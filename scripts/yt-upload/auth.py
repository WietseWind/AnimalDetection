from google_auth_oauthlib.flow import InstalledAppFlow
import json
import socket
import webbrowser

SCOPES = ['https://www.googleapis.com/auth/youtube.upload']

# First, let's make sure we can actually start a local server
def find_free_port():
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.bind(('', 0))
        s.listen(1)
        port = s.getsockname()[1]
        return port

try:
    port = find_free_port()
    print(f"\nStarting authorization flow on port {port}")
    
    flow = InstalledAppFlow.from_client_secrets_file(
        'client_secrets.json',
        scopes=SCOPES
    )
    
    # This will start a local server and open your browser
    print("\nA browser window should open automatically.")
    print("If it doesn't, please manually copy and paste the URL that will be printed below.")
    credentials = flow.run_local_server(
        port=port,
        success_message="Authorization complete! You can close this window.",
        open_browser=True
    )

    creds_data = {
        "token": credentials.token,
        "refresh_token": credentials.refresh_token,
        "token_uri": credentials.token_uri,
        "client_id": credentials.client_id,
        "client_secret": credentials.client_secret,
        "scopes": credentials.scopes
    }

    print('\nHere are your credentials (copy this entire JSON object):\n')
    print(json.dumps(creds_data, indent=2))
    
    # Also save to a file for convenience
    with open('youtube-upload-credentials.json', 'w') as f:
        json.dump(creds_data, f, indent=2)
    print('\nCredentials have also been saved to youtube-upload-credentials.json')

except Exception as e:
    print(f"\nError during authorization: {str(e)}")
    print("\nIf you're having trouble with the automatic browser opening,")
    print("please make sure you have a default web browser set and can access localhost.")