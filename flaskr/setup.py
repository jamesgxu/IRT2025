import datetime
import functools
import os

from .utils import preprocessing, gastruloid_processing, normalize, plot_results
from flask import (
    Blueprint, flash, g, redirect, render_template, request, session, url_for
)

from flaskr.db import get_db

bp = Blueprint('setup', __name__, url_prefix='/setup')

@bp.before_app_request
def load_profile():
    profile_id = session.get('profile_id')

    if profile_id is None:
        g.profile_id = None
    else:
        g.profile = get_db().execute(
            'SELECT * FROM profiles WHERE id = ?', (profile_id,)
        ).fetchone()

@bp.route('/api/profile/<int:profile_id>')
def get_profile_json(profile_id):
    profile = get_db().execute("SELECT * FROM profiles WHERE id = ?", (profile_id,)).fetchone()
    if not profile:
        return {}, 404
    return dict(profile)


@bp.route('/prompt', methods=('GET', 'POST'))
def prompt():
    db = get_db()
    profiles = db.execute("SELECT id, name FROM profiles").fetchall()

    if request.method == 'POST':
        if 'use_existing' in request.form:
            selected_id = request.form.get('existing_profile')
            if selected_id:
                session['profile_id'] = selected_id
                return redirect(url_for("setup.loading"))

            
        profile_name = request.form['profile_name']
        directory = request.form['directory']
        base_name = request.form['base_name']
        channels = request.form['channels']
        gastruloid_min_size = int(request.form.get('gastruloid_min_size', 6000))  # fallback to default


        dapi_suffix = request.form['dapi_suffix']
        red_suffix = request.form['red_suffix']

        green_suffix = request.form['green_suffix']
        cyan_suffix = request.form['cyan_suffix']
        red_marker = request.form['red_marker']
        green_marker = request.form['green_marker']
        cyan_marker = request.form['cyan_marker']


        db = get_db()
        error = None

        if not profile_name:
            error = 'Profile Name is required.'
        elif not directory:
            error = 'Directory is required.'
        elif not base_name:
            error = 'base_name is required.'
        elif not channels:
            error = 'channels is required.'
        elif not dapi_suffix:
            error = 'dapi_suffix is required.'
        elif not red_suffix:
            error = 'red_suffix is required.'
        elif not green_suffix:
            error = 'green_suffix is required.'
        elif not cyan_suffix:
            error = 'cyan_suffix is required.'
        elif not red_marker:
            error = 'red_marker is required.'
        elif not green_marker:
            error = 'green_marker is required.'
        elif not cyan_marker:
            error = 'cyan_marker is required.'
        elif not gastruloid_min_size:
            error = 'gastruloid_min_size is required.'

        if error is None:
            try:
                cursor = db.execute(
                    """
                    INSERT INTO profiles (
                        name, directory, base_name, channels,
                        dapi_suffix, red_suffix, green_suffix, cyan_suffix,
                        red_marker, green_marker, cyan_marker,
                        gastruloid_min_size
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    """,
                    (
                        profile_name, directory, base_name, channels,
                        dapi_suffix, red_suffix, green_suffix, cyan_suffix,
                        red_marker, green_marker, cyan_marker,
                        gastruloid_min_size
                    )
                )
                db.commit()
                session['profile_id'] = cursor.lastrowid  # Save the new profile ID to session
            except db.IntegrityError:
                error = f"Profile already exists. Choose a different name."

            else:
                return redirect(url_for("setup.loading"))

        flash(error)



    return render_template('setup/prompt.html', profiles=profiles)


@bp.route('/loading')
def loading():
    profile_id = session.get('profile_id')
    if not profile_id:
        flash("No profile selected or created.")
        return redirect(url_for('setup.prompt'))

    profile = get_db().execute(
        "SELECT * FROM profiles WHERE id = ?", (profile_id,)
    ).fetchone()

    return render_template("setup/loading.html", profile=dict(profile))  # Just shows "Loading..." splash


@bp.route('/process')
def process():
    profile_id = session.get('profile_id')
    if not profile_id:
        flash("No profile selected or created.")
        return redirect(url_for('setup.prompt'))

    db = get_db()
    profile = db.execute("SELECT * FROM profiles WHERE id = ?", (profile_id,)).fetchone()
    if profile is None:
        flash("Profile not found.")
        return redirect(url_for('setup.prompt'))

    directory = profile['directory']
    channels = int(profile['channels'])

    try:
        num_sets, image_list = preprocessing.preprocess_directory(directory, channels)
    except Exception as e:
        flash(str(e))
        return redirect(url_for("setup.prompt"))

    channel_name_responses = {
        'dapi': profile['dapi_suffix'],
        'red': profile['red_suffix'],
        'green': profile['green_suffix'],
        'cyan': profile['cyan_suffix']
    }

    marker_name_responses = {
        'red': profile['red_marker'],
        'green': profile['green_marker'],
        'cyan': profile['cyan_marker']
    }

    results_table, blue_int, red_int, green_int, cyan_int = gastruloid_processing.process_all_image_sets(
        num_sets,
        profile['base_name'],
        directory,
        channel_name_responses,
        marker_name_responses,
        profile['gastruloid_min_size'],
    )

    results_table, a_blue, a_red, a_green, a_cyan = normalize.run(
        results_table, blue_int, red_int, green_int, cyan_int
    )

    profile_name = profile['name']
    timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    results_dir = os.path.join(
        os.path.dirname(__file__), 'static', 'results', f"{profile_name}_{timestamp}"
    )
    os.makedirs(results_dir, exist_ok=True)

    plot_results.run(results_table, a_blue, a_red, a_green, a_cyan, marker_name_responses, num_sets, results_dir)

    return redirect(url_for('show_results', profile_name=profile_name, timestamp=timestamp))

@bp.route('/session-debug')
def session_debug():
    return dict(session)
