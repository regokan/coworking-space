""" Flask app for analytics """

import os

from apscheduler.schedulers.background import BackgroundScheduler
from flask import jsonify
from sqlalchemy import text
from sqlalchemy.exc import SQLAlchemyError

from config import app, db


port_number = int(os.environ.get("APP_PORT", 5153))


@app.route("/health_check")
def health_check():
    """
    Returns 'ok', used by k8s for health checks
    """
    return "ok"


@app.route("/readiness_check")
def readiness_check():
    """
    Returns 'ok' if the database has at least one token, used by k8s for readiness checks
    """
    try:
        _ = db.session.execute(text("SELECT COUNT(*) FROM tokens")).scalar()
    except SQLAlchemyError as e:  # Catch specific SQLAlchemy errors
        app.logger.error(f"Database error: {e}")
        return "failed", 500
    return "ok"


def get_daily_visits():
    """
    Returns a dictionary with the number of visits per day
    """
    with app.app_context():
        result = db.session.execute(
            text(
                """
        SELECT Date(created_at) AS date,
            Count(*)         AS visits
        FROM   tokens
        WHERE  used_at IS NOT NULL
        GROUP  BY Date(created_at)
        """
            )
        )

        response = {}
        for row in result:
            response[str(row[0])] = row[1]

        app.logger.info(response)

    return response


@app.route("/api/reports/daily_usage", methods=["GET"])
def daily_visits():
    """`
    Returns a dictionary with the number of visits per day
    """
    return jsonify(get_daily_visits())


@app.route("/api/reports/user_visits", methods=["GET"])
def all_user_visits():
    """
    Returns a dictionary with the number of visits per user
    """
    result = db.session.execute(
        text(
            """
    SELECT t.user_id,
        t.visits,
        users.joined_at
    FROM   (SELECT tokens.user_id,
                Count(*) AS visits
            FROM   tokens
            GROUP  BY user_id) AS t
        LEFT JOIN users
                ON t.user_id = users.id;
    """
        )
    )

    response = {}
    for row in result:
        response[row[0]] = {"visits": row[1], "joined_at": str(row[2])}

    return jsonify(response)


scheduler = BackgroundScheduler()
job = scheduler.add_job(get_daily_visits, "interval", seconds=30)
scheduler.start()

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=port_number)
