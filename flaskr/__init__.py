import os
from flask import (Flask, flash, redirect, render_template, url_for)
from . import db, setup
from flaskr.db import get_db



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
    
    @app.route('/results/<profile_name>/<timestamp>')
    def show_results(profile_name, timestamp):
        # You should probably also load profile to get marker info
        db = get_db()
        profile = db.execute("SELECT * FROM profiles WHERE name = ?", (profile_name,)).fetchone()

        if not profile:
            flash("Profile not found.")
            return redirect(url_for('setup.prompt'))

        directory = os.path.join(
            os.path.dirname(__file__), 'static', 'results', f"{profile_name}_{timestamp}"
        )

        # Count how many individual result images exist
        num_sets = len([f for f in os.listdir(directory) if f.startswith("set_") and f.endswith(".png")])

        return render_template(
            'show_results.html',
            profile_name=profile_name,
            timestamp=timestamp,
            num_sets=num_sets,
            cyan_marker=bool(profile["cyan_marker"])
        )

    return app
    # a simple page that says hello