from typing import Any
from fastapi import WebSocket, FastAPI
from models import Device
import asyncio
from fastapi import WebSocketDisconnect

class WebSocketManager:
    def __init__(self):
        # 保存当前在线设备
        # key: device_id
        # value: Device对象
        self.device_connections: dict[str, Device] = {}
        # 保存等待中的命令
        # key: device_id
        # value: Future
        #self.command_waiters: dict[str, asyncio.Future] = {}
        self.command_waiters: dict[str, Any] = {}

    # 注册WebSocket接口
    def registerSocket(self, app: FastAPI):
        @app.websocket("/device/connect")
        async def device_connect(websocket: WebSocket):
            # 接受设备连接
            await websocket.accept()
            try:
                while True:
                    data = await websocket.receive_text()
                    # 协议: device_id;device_name;command_type;command
                    protocol = data.split(";")
                    device_id = protocol[0]
                    device_name = protocol[1]
                    command_type = protocol[2]
                    command = protocol[3]
                    # 设备上电
                    if command_type == "01":
                        self.handle_connect(device_id, device_name, websocket)
                    # 心跳
                    elif command_type == "02":
                        self.handle_heartbeat(device_id)
                    # 设备执行结果
                    elif command_type == "03":
                        self.handle_command_result(device_id, command)
            except WebSocketDisconnect:
                print("设备断开:", websocket)

    def handle_connect(self, device_id: str, device_name: str, websocket: WebSocket):
        # 设备有在列表里表示重连
        if device_id in self.device_connections:
            device = self.device_connections[device_id]
            device.websocket = websocket
            device.update_active_time()
            print("设备重新连接:", device_id)
        else:
            device = Device(device_id, device_name, websocket)
            self.device_connections[device_id] = device
            print("设备首次连接:", device_id)

    def handle_heartbeat(self, device_id: str):
        device = self.device_connections.get(device_id)
        if device is None:
            return
        device.update_active_time()
        print("设备心跳:", device_id)

    def handle_command_result(self, device_id: str, command: str):
        # 查找等待该设备结果的HTTP请求
        future = self.command_waiters.get(device_id)
        if future is None:
            print("没有等待中的命令:", device_id)
            return
        # 解析设备执行结果
        if command == "0x01":
            result = {
                "success": True,
                "device_id": device_id,
                "message": "执行成功"
            }
        elif command == "0x02":
            result = {
                "success": False,
                "device_id": device_id,
                "message": "执行失败"
            }
        else:
            result = {
                "success": False,
                "device_id": device_id,
                "message": "未知返回码"
            }
        # 唤醒send_command中的等待
        future.set_result(result)
        print("设备执行结果:", result)

    # HTTP接口，获取在线设备列表
    def get_device_list(self):
        result = []
        for dev in list(self.device_connections.values()):
            result.append({
                "device_id": dev.device_id,
                "device_name": dev.device_name,
                "active_time": dev.active_time
            })
        return result

    # Server发送心跳，协议: 设备ID;_;02;0x01
    async def heartbeat_task(self):
        while True:
            for dev in list(self.device_connections.values()):
                try:
                    message = f"{dev.device_id};_;02;0x01"
                    await dev.websocket.send_text(message)
                except Exception:
                    print("发送心跳失败:", dev.device_id)
            await asyncio.sleep(180)

    # Server主动发送设备命令
    async def send_command(self, device_id: str, command: str):
        device = self.device_connections.get(device_id)
        if device is None:
            return False
        # 创建一个等待对象，HTTP请求发送命令后，需要等待设备执行结果
        # 设备返回结果后，在handle_command_result中通过future.set_result()唤醒这里
        future = asyncio.get_running_loop().create_future()
        # 保存当前设备对应的等待对象
        self.command_waiters[device_id] = future
        # 根据设备通信协议生成控制命令
        # 格式: 设备ID;_;命令类型;命令码
        # 示例: AC001;_;03;0x10
        message = f"{device_id};_;03;{command}"
        # 通过WebSocket长连接发送给对应设备
        await device.websocket.send_text(message)
        try:
            # 等待设备返回执行结果
            # 这里的result就是handle_command_result()的结果
            # 通过future.set_result()传入的数据
            # 例如:
            # {
            #     "success": True,
            #     "message": "执行成功",
            #     "device_id": "AC001"
            # }
            # timeout防止设备无响应导致HTTP请求一直等待
            result = await asyncio.wait_for(future, timeout=10)
            # 将设备执行结果返回给调用send_command()的HTTP接口
            return result
        except asyncio.TimeoutError:
            return {
                "success": False,
                "message": "设备响应超时"
            }
        finally:
            # 清理当前设备等待任务，避免Future长期保存在内存中
            self.command_waiters.pop(device_id, None)

