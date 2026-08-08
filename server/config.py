import json

class Config:
    APP_ID = ""
    APP_NAME = ""

    @classmethod
    def load(cls):
        with open("config/config.json", "r", encoding="UTF-8") as f:
            data = json.load(f)
        cls.APP_ID = data["app_id"]
        cls.APP_NAME = data["app_name"]