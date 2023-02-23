FROM solr:8.11.2-slim

ADD --chown=solr:solr rootfs/opt/solr/ /opt/solr/
ADD --chown=solr:solr rootfs/var/solr/data/ /var/solr/data/
