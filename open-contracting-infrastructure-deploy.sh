# Create private key from environment variable
# (with a couple of character substitutions so that Travis will handle it
# properly)
echo "$PRIVATE_KEY" | tr '#' '\n' | tr '_' ' ' > id_rsa
chmod 600 id_rsa
# Add host key for relevant server
echo 'staging.docs.opencontracting.uk0.bigv.io ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDk8O226B/sYkPqyHdNBdjUFCEpT9IMdUxgFXEOtlPq1QnwTgHY76PsaOin7KhJcBrm8RAOuzoOIrKfgUJjXoxCtx1edp594tD8OChF5koHyO8YkQVlJmH8LrV16txsxokfh2F31ofRIVMk+TXiEfvR4+WehqeR24TwnXzlLIv1KfMJB7znTDdwqZS3uONKjlNNzSBNNIvCZ4WTI6etVlCzQgv4HL9QllKGfk1ctDuwOgsGPMT8f5NNPhI/z7kZkNbcrHJ5Mo6ZtF26qFmZ3Hy6vxJAQ2C4/x/Zemtb0MbIvI4Qlghh3bl5lER1rB54oMg+DidJ36qMrbqEtZxrBwvP' >> ~/.ssh/known_hosts
# Get lftp binary if necessary
if hash lftp 2>/dev/null; then
    LFTP=lftp
else
    wget "https://raw.githubusercontent.com/OpenDataServices/opendataservices-deploy/master/lftp"
    chmod a+x ./lftp
    LFTP=./lftp
fi
# Make a test ssh connection, as lftp doesn't output key errors so well
# ssh -i id_rsa ocds-docs@dev3.default.opendataservices.uk0.bigv.io
# Copy the files to the server
$LFTP -c "set sftp:connect-program \"ssh -i id_rsa\"; connect sftp://ocds-docs:xxx@staging.docs.opencontracting.uk0.bigv.io; mirror -eR build web/infrastructure/$TRAVIS_BRANCH"
# Arguments to mirror are -R for recursive and -e to delete old files
