from flask import Flask, request, jsonify
import utils

app = Flask(__name__)


@app.route("/items", methods=["GET"])
def get_items():
    conn = utils.get_connection()
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

    conn = utils.get_connection()
    with conn:
        with conn.cursor() as cursor:
            cursor.execute("INSERT INTO items (name, quantity) VALUES (%s, %s)", (name, quantity))
            conn.commit()

    return jsonify({"message": "Item added successfully"}), 201

if __name__ == "__main__":
    utils.init_db()
    app.run(host="0.0.0.0", port=3000)