from fastapi import FastAPI
import uvicorn

app = FastAPI()


@app.get("/get")
def getMsgList():
    msgList = [
        'test1',
        'test2',
        'test3'
    ]
    return {
        "code": 200,
        "data": msgList
    }


if __name__ == "__main__":
    uvicorn.run(
        app,
        host="127.0.0.1",
        port=8000,
        reload=False
    )
