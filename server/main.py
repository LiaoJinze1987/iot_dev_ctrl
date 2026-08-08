from contextlib import asynccontextmanager

from config import Config
from fastapi import FastAPI
from app.http_controller import HttpController
from dev.socket_mgr import WebSocketManager
import uvicorn
import asyncio

# 解析json
Config.load()

socket_mgr = WebSocketManager()
# Server启动后自动启动心跳线程
# deprecated（已弃用），官方推荐使用 lifespan
#@app.on_event("startup")
@asynccontextmanager
async def lifespan(_app: FastAPI):
    asyncio.create_task(socket_mgr.heartbeat_task())
    #把程序执行权交给FastAPI，FastAPI开始正常运行；等FastAPI准备关闭时，再从yield后面继续执行
    yield
    print("Server Shutdown")

app = FastAPI(lifespan=lifespan)
# 注册websocket
socket_mgr.registerSocket(app)
# 注册HTTP
http_controller = HttpController(socket_mgr)
app.include_router(http_controller.route)

if __name__ == "__main__":
    uvicorn.run(
        app,
        host="192.168.1.13",
        port=8000,
        reload=False
    )