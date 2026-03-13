from flask import Flask, request, jsonify, render_template
import boto3
import os
import psycopg2  # PostgreSQL library for Python
from datetime import datetime  # to record upload time

app = Flask(__name__)

# S3 configuration
S3_BUCKET = os.environ.get("S3_BUCKET")
AWS_REGION = os.environ.get("AWS_REGION")

# PostgreSQL configuration
DB_HOST = os.environ.get("DB_HOST")
DB_NAME = os.environ.get("DB_NAME")
DB_USER = os.environ.get("DB_USER")
DB_PASSWORD = os.environ.get("DB_PASSWORD")

# S3 client
s3_client = boto3.client("s3", region_name=AWS_REGION)

# connect to PostgreSQL
def get_db():
    conn = psycopg2.connect(
        host=DB_HOST,
        database=DB_NAME,
        user=DB_USER,
        password=DB_PASSWORD
    )
    return conn

# create uploads table if not exists
def init_db():
    conn = get_db()
    cur = conn.cursor()
    cur.execute("""
        CREATE TABLE IF NOT EXISTS uploads (
            id SERIAL PRIMARY KEY,
            filename VARCHAR(255),
            file_size VARCHAR(50),
            upload_time TIMESTAMP,
            status VARCHAR(50)
        )
    """)
    conn.commit()
    cur.close()
    conn.close()

# ROUTE 1 - show homepage
@app.route("/")
def index():
    # get upload history from PostgreSQL
    conn = get_db()
    cur = conn.cursor()
    cur.execute("SELECT filename, file_size, upload_time, status FROM uploads ORDER BY upload_time DESC")
    uploads = cur.fetchall()
    cur.close()
    conn.close()
    return render_template("index.html", uploads=uploads)

# ROUTE 2 - upload file
@app.route("/upload", methods=["POST"])
def upload():
    file = request.files["file"]

    if file:
        # get file size
        file.seek(0, 2)  # move to end of file
        file_size = file.tell()  # get size in bytes
        file.seek(0)  # move back to start

        # upload to S3
        s3_client.upload_fileobj(file, S3_BUCKET, file.filename)

        # record in PostgreSQL
        conn = get_db()
        cur = conn.cursor()
        cur.execute(
            "INSERT INTO uploads (filename, file_size, upload_time, status) VALUES (%s, %s, %s, %s)",
            (file.filename, f"{file_size} bytes", datetime.now(), "uploaded")
        )
        conn.commit()
        cur.close()
        conn.close()

        return jsonify({"message": f"{file.filename} uploaded successfully!"})

    return jsonify({"message": "No file found"})

# ROUTE 3 - delete file
@app.route("/delete/<filename>", methods=["DELETE"])
def delete(filename):
    # delete from S3
    s3_client.delete_object(Bucket=S3_BUCKET, Key=filename)

    # update status in PostgreSQL
    conn = get_db()
    cur = conn.cursor()
    cur.execute(
        "UPDATE uploads SET status = %s WHERE filename = %s",
        ("deleted", filename)
    )
    conn.commit()
    cur.close()
    conn.close()

    return jsonify({"message": f"{filename} deleted successfully!"})

if __name__ == "__main__":
    init_db()  # create table when app starts
    app.run(host="0.0.0.0", port=5000, debug=True)
