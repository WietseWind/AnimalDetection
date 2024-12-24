from google_auth_oauthlib.flow import InstalledAppFlow
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload
from google.oauth2.credentials import Credentials
import os
import sys
import json

SCOPES = ['https://www.googleapis.com/auth/youtube.upload']

def get_authenticated_service():
    creds = None
    if os.path.exists('youtube-upload-credentials.json'):
        try:
            creds = Credentials.from_authorized_user_file('youtube-upload-credentials.json', SCOPES)
        except Exception as e:
            print(f"Error loading credentials: {e}")
    
    if not creds or not creds.valid:
        if not os.path.exists('client_secrets.json'):
            print("Error: client_secrets.json not found")
            sys.exit(1)
        
        flow = InstalledAppFlow.from_client_secrets_file('client_secrets.json', SCOPES)
        creds = flow.run_local_server(port=0)
        
        # Save the credentials for future use
        with open('youtube-upload-credentials.json', 'w') as token:
            token.write(creds.to_json())
    
    return build('youtube', 'v3', credentials=creds)

def upload_video(youtube, file, title, description):
    body = {
        'snippet': {
            'title': title,
            'description': description,
            'categoryId': '15'  # Pets & Animals category
        },
        'status': {
            'privacyStatus': 'private',  # Start as private for safety
            'selfDeclaredMadeForKids': False
        }
    }

    insert_request = youtube.videos().insert(
        part=','.join(body.keys()),
        body=body,
        media_body=MediaFileUpload(file, chunksize=1024*1024, resumable=True)
    )

    print(f'Starting upload of {file}...')
    response = None
    last_progress = 0
    
    while response is None:
        try:
            status, response = insert_request.next_chunk()
            if status:
                progress = int(status.progress() * 100)
                if progress != last_progress:
                    print(f'Uploaded {progress}%')
                    last_progress = progress
        except Exception as e:
            print(f'An error occurred: {e}')
            return None
    
    if response:
        video_id = response['id']
        print(f'Upload Complete!')
        print(f'Video ID: {video_id}')
        print(f'Video URL: https://youtu.be/{video_id}')
        return video_id
    
    return None

if __name__ == '__main__':
    if len(sys.argv) != 4:
        print("Usage: python3 upload.py <video_file> <title> <description>")
        sys.exit(1)
        
    video_file = sys.argv[1]
    title = sys.argv[2]
    description = sys.argv[3]
    
    if not os.path.exists(video_file):
        print(f"Error: Video file '{video_file}' not found")
        sys.exit(1)
    
    youtube = get_authenticated_service()
    upload_video(youtube, video_file, title, description)
