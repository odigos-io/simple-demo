import os
import sys
import logging

# append known location for deps in distributed packages
dep_location = os.path.normpath(os.path.join(os.path.dirname(__file__), '..', 'site-packages'))
sys.path.append(dep_location)

from flask import Flask, request, jsonify
import time
import signal

PORT = os.environ["PORT"] if "PORT" in os.environ else 8080

logging.getLogger().setLevel(logging.INFO)

app = Flask(__name__)

class InventoryItem:
    def __init__(self, id, name, image):
        self.id = id
        self.name = name
        self.image = image

inventory_items = [
    InventoryItem(1, "T Shirt", "https://emoji.aranja.com/static/emoji-data/img-apple-160/1f455.png"),
    InventoryItem(2, "Pants", "https://emoji.aranja.com/static/emoji-data/img-apple-160/1f456.png"),
    InventoryItem(3, "Shoes", "https://emoji.aranja.com/static/emoji-data/img-apple-160/1f462.png"),
    InventoryItem(4, "Hat", "https://emoji.aranja.com/static/emoji-data/img-apple-160/1f9e2.png"),
    InventoryItem(5, "Socks", "https://emoji.aranja.com/static/emoji-data/img-apple-160/1f9e6.png"),
    InventoryItem(6, "Gloves", "https://emoji.aranja.com/static/emoji-data/img-apple-160/1f9e4.png"),
    InventoryItem(7, "Scarf", "https://emoji.aranja.com/static/emoji-data/img-apple-160/1f9e3.png"),
    InventoryItem(8, "Jacket", "https://emoji.aranja.com/static/emoji-data/img-apple-160/1f9e5.png"),
    InventoryItem(9, "Kimono", "https://emoji.aranja.com/static/emoji-data/img-apple-160/1f458.png"),
    InventoryItem(10, "Purse", "https://emoji.aranja.com/static/emoji-data/img-apple-160/1f45b.png"),
    InventoryItem(11, "Tophat", "https://emoji.aranja.com/static/emoji-data/img-apple-160/1f3a9.png"),
    InventoryItem(12, "Watch", "https://emoji.aranja.com/static/emoji-data/img-apple-160/231a.png"),
    InventoryItem(13, "Sunglasses", "https://emoji.aranja.com/static/emoji-data/img-apple-160/1f576-fe0f.png"),
    InventoryItem(14, "Womans Hat", "https://emoji.aranja.com/static/emoji-data/img-apple-160/1f452.png"),
    InventoryItem(15, "Sandal", "https://emoji.aranja.com/static/emoji-data/img-apple-160/1f461.png"),
    InventoryItem(16, "Bracelet", "https://emoji.aranja.com/static/emoji-data/img-apple-160/1f4ff.png"),
    InventoryItem(17, "Ring", "https://emoji.aranja.com/static/emoji-data/img-apple-160/1f48d.png"),
    InventoryItem(18, "Suit", "https://emoji.aranja.com/static/emoji-data/img-apple-160/1f454.png"),
    InventoryItem(19, "Dress", "https://emoji.aranja.com/static/emoji-data/img-apple-160/1f457.png"),
    InventoryItem(20, "Eyeglasses", "https://emoji.aranja.com/static/emoji-data/img-apple-160/1f453.png")
]

@app.route('/inventory', methods=['GET'])
def get_inventory():
    logging.info("Returning inventory")
    return jsonify([item.__dict__ for item in inventory_items])

@app.route('/buy', methods=['POST'])
def buy_product():
    product_id = request.args.get('id', type=int)
    logging.info(f"Buying product with id {product_id}")
    time.sleep(1)
    return jsonify({"message": "Product purchased successfully"})

def signal_handler(sig, frame):
    logging.info('Terminating inventory service')
    sys.exit(0)

if __name__ == '__main__':
    signal.signal(signal.SIGTERM, signal_handler)
    app.run(debug=False, port=PORT, host='0.0.0.0')