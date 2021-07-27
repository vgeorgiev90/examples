#!/bin/bash

set -e

CHOICE=${1}

case ${CHOICE} in
	'bash')
		exec /bin/bash
		;;
	*)	
		echo "from django.contrib.auth.models import User; User.objects.create_superuser('"${DJANGO_SUPERUSER_USERNAME}"', '"${DJANGO_SUPERUSER_EMAIL}"', '"${DJANGO_SUPERUSER_PASSWORD}"')" | python manage.py shell 2>/dev/null || true
		python manage.py migrate --noinput 
		gunicorn mysite.wsgi:application
		;;
esac
