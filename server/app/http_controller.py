from fastapi import APIRouter
from models import AppCheckRequest, DeviceCommandRequest
from config import Config

#接口请求合集
class HttpController:

    def __init__(self, socket_mgr):
        self.route = APIRouter()
        self.socket_mgr = socket_mgr
        #接口合集
        self.route.add_api_route("/appCheck", self.appCheck, methods=["POST"])
        self.route.add_api_route("/deviceList", self.deviceList, methods=["GET"])
        self.route.add_api_route("/deviceCommand", self.deviceCommand, methods=["POST"])

    def appCheck(self, check: AppCheckRequest):
        app_id = check.app_id
        app_name = check.app_name
        if app_id != Config.APP_ID or app_name != Config.APP_NAME:
            return {
                "code": 201,
                "msg": "params error"
            }
        return {
            "code": 200,
            "msg": "success"
        }

    def deviceList(self):
        dev_list = self.socket_mgr.get_device_list()
        return {
            "code": 200,
            "device": dev_list
        }

    async def deviceCommand(self, request: DeviceCommandRequest):
        device_id = request.device_id
        command = request.command
        result = await self.socket_mgr.send_command(device_id, command)
        return {
            "code": 200,
            "result": result
        }