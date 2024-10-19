# Use the official Python 3.12.3 slim image as the base
FROM python:3.12.3-slim

# Set environment variables to prevent Python from buffering stdout and to use Flask
ENV PYTHONUNBUFFERED=1
ENV FLASK_APP=app.py

# Set the working directory in the container
WORKDIR /app

# Copy the Pipfile and Pipfile.lock to the container
COPY ./analytics/Pipfile ./analytics/Pipfile.lock ./

# Install Pipenv and project dependencies
RUN pip install pipenv && pipenv install --system --deploy

# Copy the rest of the application code to the container
COPY ./analytics ./

# Expose the port that the app will be running on
EXPOSE 5153

# Command to run the Flask application
CMD ["flask", "run", "--host=0.0.0.0", "--port=5153"]
