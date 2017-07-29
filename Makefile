
start-jupiter:
	jupyter notebook --ip=0.0.0.0 --notebook-dir ./jupyter_notebooks/

start-tf-board:
	tensorboard --logdir=/tmp/tflearn_logs/

create-virtenv:
	virtualenv env

install-dependency:
	pip install -r requirements.txt

save-dependency:
	pip freeze > requirements.txt
