import os
from flask import (Flask, redirect, url_for)
from . import db, setup


def create_app(test_config=None):
    app = Flask(__name__, instance_relative_config=True)
    app.config.from_mapping(
        SECRET_KEY = 'dev',
        DATABASE=os.path.join(app.instance_path, 'flaskr.sqlite')
    )
    if test_config is None:
        # load the instance config, if it exists, when not testing
        app.config.from_pyfile('config.py', silent=True)
    else:
        # load the test config if passed in
        app.config.from_mapping(test_config)

    try:
        os.makedirs(app.instance_path)
    except OSError:
        pass

    db.init_app(app)

    app.register_blueprint(setup.bp)

    @app.route('/hello')
    def hello():
            return 'Hello, World!'
    
    @app.route('/')
    def redirect_to_setup():
         return redirect(url_for("setup.prompt"))

    return app
    # a simple page that says hello