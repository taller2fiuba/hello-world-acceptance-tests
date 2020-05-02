import os

def raise_value_error(message):
    '''
    Lanza una excepción de tipo ValueError con el mensaje indicado.
    '''
    raise ValueError(message)

NODE_URL=os.environ.get('NODE_URL') or raise_value_error('Falta la variable de entorno NODE_URL')
FLASK_URL=os.environ.get('FLASK_URL') or raise_value_error('Falta la variable de entorno FLASK_URL')

