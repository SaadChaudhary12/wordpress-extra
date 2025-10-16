import pymysql
import boto3
import json
import os

def get_db_credentials():
    secret_name = os.getenv("DB_SECRET_NAME", "Saad-Secret-sq1")
    region_name = os.getenv("AWS_REGION", "us-east-1")

    session = boto3.session.Session()
    client = session.client(service_name="secretsmanager", region_name=region_name)

    secret_value = client.get_secret_value(SecretId=secret_name)
    secret_dict = json.loads(secret_value["SecretString"])
    return secret_dict

db_creds = get_db_credentials()
DB_HOST = db_creds["DB_HOST"]
DB_USER = db_creds["DB_USER"]
DB_PASS = db_creds["DB_PASS"]
DB_NAME = db_creds["DB_NAME"]



def get_connection():
    return pymysql.connect(
        host=DB_HOST,
        user=DB_USER,
        password=DB_PASS,
        database=DB_NAME,
        cursorclass=pymysql.cursors.DictCursor
    )

def init_db():
    try:
        conn = get_connection()
        with conn:
            with conn.cursor() as cursor:
                cursor.execute(f"CREATE DATABASE IF NOT EXISTS {DB_NAME}")
                cursor.execute(f"USE {DB_NAME}")
                cursor.execute("""
                    CREATE TABLE IF NOT EXISTS items (
                        id INT AUTO_INCREMENT PRIMARY KEY,
                        name VARCHAR(100),
                        quantity INT
                    )
                """)
                conn.commit()
        print("Database and table verified/created successfully.")
    except Exception as e:
        print("Error initializing database:", e)