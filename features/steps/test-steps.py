from behave import *
import requests

@when('llamo al index')
def step_impl(context):
    context.response = requests.get('http://localhost:27080').json()

@then('devuelve hello world')
def step_impl(context):
    assert context.response == {'title': 'Hello world by NodeJS'}
