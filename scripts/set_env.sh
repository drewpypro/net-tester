# set-env.sh
echo "Enter Let's Encrypt email:"
read LE_EMAIL
echo "Enter domain for Let's Encrypt:"
export LE_EMAIL
echo "Variables set. You can now start the container."
