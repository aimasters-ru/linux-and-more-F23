#
# Simple Flask app
#
import os
import pwd

from flask import Flask

#port=pwd.getpwnam(os.environ['USER']).pw_uid + 1000
host='127.0.0.1'
#host="0.0.0.0"
port=5000

app = Flask(__name__)

@app.route('/')
def hello_world():
    return 'Hello world!'

if __name__ == '__main__':
    app.run(debug=True, port=port, host=host)

