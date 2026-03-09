# use lightweight python base image
FROM python:3.11-slim

# set working directory inside container
WORKDIR /app

# copy requirements first for better caching
COPY requirements.txt .

# install libraries
RUN pip install -r requirements.txt

# copy rest of the code
COPY . .

# set environment variable
ENV AWS_REGION="us-east-1"

# expose port where flask runs
EXPOSE 5000

# start the app
CMD ["python", "app.py"]