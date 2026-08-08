# IoT Device Control Demo

一个基于 **Flutter + Python FastAPI + WebSocket** 实现的简易物联网设备控制 Demo。

本项目主要用于验证一个基本的 IoT 控制流程：

**Flutter App → HTTP → FastAPI Server → WebSocket → Device → WebSocket → FastAPI Server → HTTP → Flutter App**

目前使用 Flutter App 模拟实际 IoT 设备，用于在没有真实智能设备的情况下验证完整的设备通信与控制流程。

## 1. 项目结构

```text
project/
├── app/                    # Flutter 控制端 App
│   ├── ...
│
├── device/                 # Flutter 模拟设备
│   ├── ...
│
└── server/                 # Python FastAPI Server
    ├── ...
```

项目包含三个部分：

### App

Flutter 编写的控制端 App。

主要负责：

* App 身份检查
* 获取在线设备列表
* 显示设备状态
* 选择设备
* 向 Server 发送设备控制命令
* 接收并显示设备执行结果

### Server

Python FastAPI 编写的中控服务器。

主要负责：

* App HTTP 请求处理
* 设备 WebSocket 连接管理
* 在线设备管理
* 设备心跳
* 向指定设备发送控制命令
* 接收设备执行结果
* 将设备执行结果返回给 App

### Device

Flutter 编写的模拟设备。

实际项目中这里应该对应真实的智能设备。

当前模拟设备主要负责：

* 连接 Server
* 发送设备上线信息
* 接收 Server 心跳
* 回复心跳
* 接收 Server 控制命令
* 模拟执行设备操作
* 返回执行结果

---

# 2. 整体通信架构

```text
┌──────────────────┐
│   Flutter App    │
│     控制端        │
└────────┬─────────┘
         │
         │ HTTP
         │
         ▼
┌──────────────────┐
│  FastAPI Server  │
│     中控服务       │
└────────┬─────────┘
         │
         │ WebSocket
         │
         ▼
┌──────────────────┐
│ Flutter Device   │
│    模拟设备       │
└──────────────────┘
```

App 与 Server 之间使用 HTTP。

Server 与设备之间使用 WebSocket 长连接。

这样设计的主要原因是：

* App 的请求属于典型的请求/响应模式，因此 HTTP 足够。
* Server 与设备需要保持长连接，并且 Server 需要主动向设备发送消息，因此使用 WebSocket。
* Server 作为中间层负责管理设备连接，因此 App 不需要直接连接设备。

---

# 3. 基本工作流程

整个 Demo 的核心流程如下：

```text
设备启动
   │
   ▼
连接 Server WebSocket
   │
   ▼
发送设备上线信息
   │
   ▼
Server 保存设备连接
   │
   ▼
设备进入在线状态
   │
   ▼
App 请求设备列表
   │
   ▼
Server 返回在线设备
   │
   ▼
App 选择设备
   │
   ▼
App HTTP 请求 Server
   │
   ▼
Server 通过 WebSocket
向指定设备发送命令
   │
   ▼
设备接收并执行命令
   │
   ▼
设备通过 WebSocket
返回执行结果
   │
   ▼
Server 获取执行结果
   │
   ▼
Server 返回 HTTP 响应
   │
   ▼
App 显示执行结果
```

---

# 4. 设备上线

设备连接 Server 后，通过 WebSocket 发送上线消息。

当前协议格式：

```text
device_id;device_name;command_type;command
```

例如：

```text
AC001;模拟空调;01;0x00
```

其中：

```text
AC001       设备 ID
模拟空调     设备名称
01          命令类型：设备上线
0x00        命令内容
```

Server 收到 `01` 后，将设备保存到在线设备列表：

```python
self.device_connections[device_id] = device
```

Server 使用 `device_id` 作为 Key，因此可以通过设备 ID 快速找到对应设备。

---

# 5. 在线设备管理

Server 使用一个字典保存当前设备连接：

```python
self.device_connections: dict[str, Device] = {}
```

结构类似：

```text
device_connections
│
├── AC001 → Device
├── AC002 → Device
└── AC003 → Device
```

每个 `Device` 保存：

```text
device_id
device_name
websocket
active_time
```

因此 Server 不仅知道设备是否连接，还可以通过保存的 WebSocket 连接主动向设备发送消息。

---

# 6. 设备心跳

Server 会定期向在线设备发送心跳：

```text
AC001;_;02;0x01
```

设备收到 `02` 后回复：

```text
AC001;_;02;0x01
```

Server 收到设备心跳后更新：

```text
active_time
```

这样可以用于判断设备最近是否仍然活跃。

当前 Demo 的 Server 心跳间隔为：

```text
180 秒
```

---

# 7. 获取设备列表

App 通过 HTTP 请求：

```text
GET /deviceList
```

Server 从：

```python
device_connections
```

中获取当前设备列表。

返回的数据类似：

```json
{
    "code": 200,
    "device": [
        {
            "device_id": "AC001",
            "device_name": "模拟空调",
            "active_time": "..."
        }
    ]
}
```

App 将返回的数据转换成 Flutter 的 `Device` 对象并显示。

---

# 8. 设备控制

App 选择设备后，通过 HTTP 请求：

```text
POST /deviceCommand
```

请求数据：

```json
{
    "device_id": "AC001",
    "command": "0x10"
}
```

Server 收到请求后调用：

```python
await self.socket_mgr.send_command(device_id, command)
```

然后 Server 通过已经建立的 WebSocket 连接向设备发送：

```text
AC001;_;03;0x10
```

其中：

```text
03
```

表示设备控制命令。

---

# 9. Server 等待设备执行结果

设备执行命令后返回：

```text
AC001;_;03;0x01
```

或者：

```text
AC001;_;03;0x02
```

其中：

```text
0x01 = 执行成功
0x02 = 执行失败
```

Server 使用 `asyncio.Future` 将 HTTP 请求和 WebSocket 返回结果连接起来。

基本逻辑：

```text
HTTP 请求
   │
   ▼
send_command()
   │
   ├── 创建 Future
   │
   ├── 保存 Future
   │
   ├── WebSocket 发送命令
   │
   └── 等待 Future
          │
          │
          ▼
     Device 返回结果
          │
          ▼
handle_command_result()
          │
          ▼
future.set_result()
          │
          ▼
send_command() 被唤醒
          │
          ▼
HTTP 返回结果
```

这样就可以让一个 HTTP 请求等待对应设备的异步执行结果。

同时设置了超时时间：

```python
await asyncio.wait_for(future, timeout=10)
```

如果设备 10 秒内没有返回结果，则认为设备响应超时。

---

# 10. 当前实现的通信协议

当前 Demo 使用简单的字符串协议：

```text
device_id;device_name;command_type;command
```

命令类型：

| 类型   | 含义        |
| ---- | --------- |
| `01` | 设备上线      |
| `02` | 心跳        |
| `03` | 设备控制/执行结果 |

例如设备上线：

```text
AC001;模拟空调;01;0x00
```

Server 发送心跳：

```text
AC001;_;02;0x01
```

Server 发送控制命令：

```text
AC001;_;03;0x10
```

设备返回执行成功：

```text
AC001;_;03;0x01
```

设备返回执行失败：

```text
AC001;_;03;0x02
```

这个协议只是为了 Demo 简化实现，实际项目中可以根据设备协议进一步扩展。

---

# 11. 为什么使用 WebSocket

本 Demo 中：

```text
App → Server
```

使用 HTTP。

而：

```text
Server ↔ Device
```

使用 WebSocket。

主要原因是设备连接需要长期保持。

HTTP 更适合：

```text
请求 → 响应
```

而 WebSocket 建立连接后可以：

```text
Server → Device
Device → Server
```

双方都可以主动发送消息。

因此 Server 可以主动：

```text
发送心跳
发送控制命令
```

设备也可以主动：

```text
发送心跳
返回命令执行结果
```

这更加符合设备控制场景。

---

# 12. 当前 Demo 已经实现的功能

目前已经完成基本的 IoT 控制闭环：

* [x] Flutter 控制端
* [x] Python FastAPI Server
* [x] Flutter 模拟设备
* [x] WebSocket 长连接
* [x] 设备上线注册
* [x] 在线设备列表
* [x] Server 心跳
* [x] 设备心跳响应
* [x] App 获取设备列表
* [x] App 选择设备
* [x] App 发送控制命令
* [x] Server 转发控制命令
* [x] Device 接收控制命令
* [x] Device 返回执行结果
* [x] Server 等待并处理设备执行结果
* [x] App 获取最终执行结果
* [x] 三端实际联调运行

因此当前项目已经能够完成：

```text
App
 ↓
HTTP
 ↓
Server
 ↓
WebSocket
 ↓
Device
 ↓
WebSocket
 ↓
Server
 ↓
HTTP
 ↓
App
```

完整的设备控制闭环。

---

# 13. 当前 Demo 的定位

本项目定位为 **IoT 基础通信与设备控制 Demo**，重点验证：

1. App、Server、Device 三端之间的通信关系。
2. WebSocket 长连接设备管理。
3. Server 主动向设备发送消息。
4. 设备向 Server 返回异步结果。
5. HTTP 请求与 WebSocket 异步结果之间的衔接。

项目目前并非生产级 IoT 平台。

如果进一步用于实际生产环境，还需要根据实际业务增加：

* WebSocket 自动重连
* 设备离线检测
* 设备认证
* 用户认证与权限控制
* WSS 加密通信
* 命令唯一 ID
* 多命令并发控制
* 命令队列
* Redis / 数据库
* 多 Server 实例之间的设备连接管理
* 日志与监控
* 异常恢复
* 更完善的设备通信协议

这些内容属于后续工程化工作。

---

# 14. 总结

这个 Demo 的核心不是某一个 Flutter 页面或者某一个 FastAPI 接口，而是验证了一个完整的 IoT 基础架构：

```text
             HTTP
     ┌──────────────────┐
     │                  ▼
┌────┴────┐       ┌────────────┐
│ Flutter │ HTTP  │  FastAPI   │
│   App   ├──────►│   Server   │
└─────────┘       └──────┬─────┘
                         │
                     WebSocket
                         │
                         ▼
                  ┌────────────┐
                  │   Device   │
                  │ Flutter模拟 │
                  └────────────┘
```
通过这个项目，完成了从**设备连接、设备管理、心跳维持、命令下发，到设备执行结果返回**的基本 IoT 通信流程。
真实设备接入时，只需要将当前 Flutter 模拟设备替换成实际设备通信端，Server 侧的核心设备管理和控制逻辑即可继续扩展。
