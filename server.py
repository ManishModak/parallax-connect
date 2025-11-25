import getpass
import socket
import uvicorn
import httpx
import qrcode
import logging
from datetime import datetime
from fastapi import (
    Depends,
    FastAPI,
    File,
    Form,
    Header,
    HTTPException,
    UploadFile,
)
from pydantic import BaseModel
from pyngrok import ngrok
from typing import Optional

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
logger = logging.getLogger(__name__)

# --- CONFIGURATION ---
# Options: "MOCK", "PROXY"
# - MOCK: Returns dummy data (for UI Dev).
# - PROXY: Forwards requests to running Parallax Service (localhost:3002).
SERVER_MODE = "MOCK"
PASSWORD: Optional[str] = None

# Parallax Service Endpoint (OpenAI Compatible)
# NOTE: Port 3001 is the scheduler which provides the API
# Port 3002 is only for the web chat UI (when running 'parallax chat')
PARALLAX_SERVICE_URL = "http://localhost:3001/v1/chat/completions"

app = FastAPI()


def setup_password():
    """Prompt user for optional password protection."""
    global PASSWORD

    try:
        choice = input("\n🔒 Set a password for this server? (y/n): ").strip().lower()
    except EOFError:
        choice = "n"

    if choice == "y":
        password = getpass.getpass("Enter password: ").strip()
        if password:
            PASSWORD = password
            print("✅ Password protection enabled\n")
        else:
            PASSWORD = None
            print("⚠️  Empty password. Server remains open.\n")
    else:
        PASSWORD = None
        print("⚠️  No password set. Server is open.\n")


async def check_password(x_password: Optional[str] = Header(default=None)):
    if PASSWORD and x_password != PASSWORD:
        raise HTTPException(status_code=401, detail="Invalid password")

    return True


def get_local_ip():
    """Get the local IP address of this machine."""
    try:
        # Connect to an external server (doesn't actually send data) to get the interface IP
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except Exception:
        return "127.0.0.1"


def print_qr(url):
    """Generate and print a QR code for the given URL to the terminal."""
    qr = qrcode.QRCode(version=1, box_size=1, border=1)
    qr.add_data(url)
    qr.make(fit=True)
    qr.print_ascii(invert=True)


@app.on_event("startup")
async def startup_event():
    logger.info(f"🚀 Server Starting... MODE: {SERVER_MODE}")

    # Test Parallax connection if in PROXY mode
    if SERVER_MODE == "PROXY":
        logger.info(f"Testing connection to Parallax at {PARALLAX_SERVICE_URL}...")
        try:
            async with httpx.AsyncClient() as client:
                resp = await client.get("http://localhost:3001/health", timeout=5.0)
                logger.info("✅ Parallax connection successful")
        except Exception as e:
            logger.warning(f"⚠️ Cannot reach Parallax: {e}")
            logger.warning("Make sure Parallax is running: parallax run")

    setup_password()

    # 1. Get Local URL
    local_ip = get_local_ip()
    local_url = f"http://{local_ip}:8000"

    # 2. Try to start Ngrok Tunnel
    public_url = None
    try:
        # pyngrok automatically loads the auth token from the config file
        http_tunnel = ngrok.connect(8000)
        public_url = http_tunnel.public_url
    except Exception as e:
        error_msg = str(e).lower()
        if "authtoken" in error_msg or "authentication" in error_msg:
            print("⚠️ Ngrok Auth Token not found. Skipping Cloud Tunnel.")
            print("   Run: ngrok config add-authtoken <TOKEN> to enable Cloud Mode.")
        else:
            print(f"⚠️ Could not start Ngrok: {e}")

    # 3. Display Connection Info & QR Code
    print("\n" + "=" * 50)
    print("📲 CONNECT YOUR APP")
    print("=" * 50)

    if public_url:
        print(f"\n🌍 CLOUD MODE (Recommended)")
        print(f"URL: {public_url}")
        print("Scan this QR code to connect:\n")
        print_qr(public_url)
        print("\n" + "-" * 50)

    print(f"\n🏠 LOCAL MODE (Same Wi-Fi only)")
    print(f"URL: {local_url}")
    print("Scan this QR code to connect:\n")
    print_qr(local_url)

    print("=" * 50 + "\n")


@app.get("/", dependencies=[Depends(check_password)])
def home():
    logger.info("📍 Root endpoint accessed")
    return {"status": "online", "mode": SERVER_MODE, "device": "Server Node"}


@app.get("/healthz")
def health_check():
    """Public health check that doesn't require a password."""
    return {"status": "ok"}


class ChatRequest(BaseModel):
    prompt: str


@app.get("/status", dependencies=[Depends(check_password)])
async def status_endpoint():
    """Check server and Parallax connectivity status."""
    status = {
        "server": "online",
        "mode": SERVER_MODE,
        "timestamp": datetime.now().isoformat(),
    }

    if SERVER_MODE == "PROXY":
        try:
            async with httpx.AsyncClient() as client:
                resp = await client.get("http://localhost:3001/health", timeout=5.0)
                status["parallax"] = "connected"
                logger.info("✅ Parallax status check: connected")
        except Exception as e:
            status["parallax"] = "disconnected"
            status["parallax_error"] = str(e)
            logger.error(f"❌ Parallax status check failed: {e}")

    return status


@app.post("/chat", dependencies=[Depends(check_password)])
async def chat_endpoint(request: ChatRequest):
    request_id = datetime.now().strftime("%Y%m%d%H%M%S%f")
    logger.info(f"📝 [{request_id}] Received chat request: {request.prompt[:50]}...")

    if SERVER_MODE == "MOCK":
        logger.info(f"📤 [{request_id}] Returning MOCK response")
        return {
            "response": f"[MOCK] Server received: '{request.prompt}'. \n\nThis is a simulated response."
        }

    elif SERVER_MODE == "PROXY":
        # Forward to Parallax Service (OpenAI API)
        start_time = datetime.now()
        try:
            logger.info(
                f"🔄 [{request_id}] Forwarding to Parallax at {PARALLAX_SERVICE_URL}"
            )

            async with httpx.AsyncClient() as client:
                # Construct OpenAI-compatible payload
                payload = {
                    "model": "default",  # Or specific model name if needed
                    "messages": [{"role": "user", "content": request.prompt}],
                    "stream": False,
                }
                logger.debug(f"📦 [{request_id}] Payload: {payload}")

                resp = await client.post(
                    PARALLAX_SERVICE_URL, json=payload, timeout=60.0
                )

                if resp.status_code != 200:
                    logger.error(
                        f"❌ [{request_id}] Parallax returned {resp.status_code}: {resp.text}"
                    )
                    raise HTTPException(
                        status_code=resp.status_code,
                        detail=f"Parallax Error: {resp.text}",
                    )

                # Parse OpenAI response format
                data = resp.json()
                content = data["choices"][0]["message"]["content"]

                elapsed = (datetime.now() - start_time).total_seconds()
                logger.info(
                    f"✅ [{request_id}] Received response from Parallax ({elapsed:.2f}s)"
                )
                logger.debug(f"📨 [{request_id}] Response preview: {content[:100]}...")

                return {"response": content}

        except httpx.TimeoutException as e:
            logger.error(f"⏱️ [{request_id}] Parallax request timeout: {e}")
            raise HTTPException(
                status_code=504,
                detail="Parallax request timed out. The model might be processing a heavy request.",
            )
        except httpx.ConnectError as e:
            logger.error(f"🔌 [{request_id}] Cannot connect to Parallax: {e}")
            raise HTTPException(
                status_code=503,
                detail="Cannot connect to Parallax. Make sure it's running: parallax run",
            )
        except Exception as e:
            logger.error(f"❌ [{request_id}] Proxy error: {e}", exc_info=True)
            raise HTTPException(status_code=500, detail=f"Remote Service Error: {e}")


@app.post("/vision", dependencies=[Depends(check_password)])
async def vision_endpoint(image: UploadFile = File(...), prompt: str = Form(...)):
    request_id = datetime.now().strftime("%Y%m%d%H%M%S%f")
    logger.info(f"📸 [{request_id}] Vision request: {prompt[:50]}...")

    if SERVER_MODE == "MOCK":
        logger.info(f"📤 [{request_id}] Returning MOCK vision response")
        return {
            "response": f"[MOCK] Vision Analysis: I see a simulated image. Prompt: {prompt}"
        }

    # TODO: Implement Vision Proxy when Parallax supports Multi-Modal API
    logger.warning(f"⚠️ [{request_id}] Vision proxy not yet implemented")
    return {"response": "[PROXY] Vision not yet implemented in Parallax API wrapper."}


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
