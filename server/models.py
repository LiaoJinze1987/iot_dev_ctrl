from datetime import datetime
from pydantic import BaseModel
from starlette.websockets import WebSocket

class AppCheckRequest(BaseModel):
    app_id: str
    app_name: str

# websocket 设备实体
class Device:

    def __init__(self, device_id: str, device_name: str, websocket: WebSocket):
        self.device_id = device_id
        self.device_name = device_name
        self.websocket = websocket
        self.active_time = datetime.now()

    def update_active_time(self):
        self.active_time = datetime.now()

# app发生指令给设备
class DeviceCommandRequest(BaseModel):
    device_id: str
    command: str
