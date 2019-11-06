from default_config import Config as DefaultConfig


class Config(DefaultConfig):
    SQLALCHEMY_DATABASE_URI = "{{db_uri}}"
    SECRET_KEY = "{{secret_key}}"
