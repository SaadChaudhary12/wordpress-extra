from flask import Flask, request, jsonify
import pymysql

app = Flask(__name__)


DB_HOST = "terraform-20250929095000984700000001.ci6pixnrgmml.us-east-1.rds.amazonaws.com"
DB_USER = "Application"
DB_PASS = "Application"
DB_NAME = "Application"


def get_connection():
    return pymysql.connect(
        host=DB_HOST,
        user=DB_USER,
        password=DB_PASS,
        database=DB_NAME,
        cursorclass=pymysql.cursors.DictCursor
    )

@app.route("/items", methods=["GET"])
def get_items():
    conn = get_connection()
    with conn:
        with conn.cursor() as cursor:
            cursor.execute("SELECT * FROM items;")
            rows = cursor.fetchall()
    return jsonify(rows), 200

@app.route("/items", methods=["POST"])
def add_item():
    data = request.get_json()
    name = data.get("name")
    quantity = data.get("quantity")

    conn = get_connection()
    with conn:
        with conn.cursor() as cursor:
            cursor.execute("INSERT INTO items (name, quantity) VALUES (%s, %s)", (name, quantity))
            conn.commit()

    return jsonify({"message": "Item added successfully"}), 201

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=0)

