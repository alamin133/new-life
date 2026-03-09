# app.py - Flask Backend

# import flask libraries
from flask import Flask, request, jsonify, render_template  # Flask web framework
import boto3                                                 # AWS library to talk to S3
import os                                                    # to read environment variables

app = Flask(__name__)  # create Flask app — __name__ tells Flask where to look for files

# S3 configuration — read from environment variables (more secure than hardcoding)
S3_BUCKET = os.environ.get("S3_BUCKET")    # get bucket name from environment variable
AWS_REGION = os.environ.get("AWS_REGION")  # get region from environment variable

# create S3 client using boto3
s3_client = boto3.client(
    "s3",                      # we are connecting to S3 service
    region_name=AWS_REGION     # in this region
)
# boto3.client = connection to AWS service
# no need for access keys because EC2 has IAM role attached ✅


# ROUTE 1 — Show HTML page when user opens browser
@app.route("/")                          # when user goes to http://your-ec2-ip/
def index():
    return render_template("index.html") # show index.html from templates folder


# ROUTE 2 — Receive file and upload to S3
@app.route("/upload", methods=["POST"])  # when user submits form → POST request comes here
def upload():
    file = request.files["file"]         # get the file from request

    if file:                             # if file exists
        s3_client.upload_fileobj(
            file,                        # the actual file
            S3_BUCKET,                   # which bucket to upload to
            file.filename                # name of file in S3
        )
        return jsonify({                 # send success response back to user
            "message": f"{file.filename} uploaded to S3 successfully!"
        })

    return jsonify({"message": "No file found"})  # if no file sent


# ROUTE 3 — Delete file from S3
@app.route("/delete/<filename>", methods=["DELETE"])  # when user wants to delete
def delete(filename):
    s3_client.delete_object(
        Bucket=S3_BUCKET,   # which bucket
        Key=filename         # which file to delete
    )
    return jsonify({
        "message": f"{filename} deleted from S3 successfully!"
    })


# Start the Flask app
if __name__ == "__main__":
    app.run(
        host="0.0.0.0",  # listen on all network interfaces — important for Docker!
        port=5000,        # run on port 5000
        debug=True        # show errors in browser — turn off in production
    )


