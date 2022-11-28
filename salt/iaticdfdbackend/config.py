SQLALCHEMY_DATABASE_URI = 'postgresql://{{ postgres_user }}:{{ postgres_password }}@localhost/{{ postgres_name }}'
SQLALCHEMY_TRACK_MODIFICATIONS = False
BABBAGE_PAGE_MAX=1048575 # Excel maximum rows (-1 for the header)
