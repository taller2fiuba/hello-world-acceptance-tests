from behave import *
import requests

from config import NODE_URL, FLASK_URL

@when('llamo al index')
def step_impl(context):
    context.response = requests.get(NODE_URL).json()

@then('devuelve hello world')
def step_impl(context):
    assert context.response == {'title': 'Hello world by NodeJS'}
