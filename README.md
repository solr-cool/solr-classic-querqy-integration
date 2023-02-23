# ☀️ Querqy Solr 7 replication integration example

> 7️⃣ This is the integration of Querqy into a classic __Solr7__ ensemble
> For Solr8 switch to the `solr8` branch.

This is an out of the box example of a _leader/follower (master/slave)
[Solr](https://solr.apache.org/guide/7_3/) ensemble_
with the [_Querqy 5 query parser_](https://docs.querqy.org/querqy/index.html)
and rewriting engine enabled.

The example create a simple core on two Solr instances and has replication
between both enabled. Querqy rules are configured on the leader Solr instance
and upon commit replicated to the follower instance.

## ☝️ Solr & Querqy configuration gotchas

* Querqy rules are replicated from the leader to the follower nodes
* Querqy stores the uploaded rewriter files in the Solr Cores data directory
* The storage schema in the data directory is `querqy/rewriters/<REWRITER_NAME>`
* Querqy rule replication needs specific configuration of the Solr
  replication handler:
    * The [`confFiles` setting](https://solr.apache.org/guide/7_3/index-replication.html#replicating-configuration-files)
      in the replication handler needs to list all Querqy rewriter files.
    * The settings does not allow wildcard entries, separate files via comma.
    * In the example below, we create the `common_rules` rewriter. The resulting
      entry in the replication handlers `confFiles` setting is `querqy/rewriters/common_rules`
    * _If you want to configure more than one rewriter in Querqy, you need a
      corresponding entry in the replication handlers `confFiles` setting!_

## 🏗️ Solr modifications for Querqy

1. Add the [Querqy library](rootfs/opt/solr/contrib/querqy/lib/querqy-solr-5.2.lucene720.0-jar-with-dependencies.jar)
   suitable for your Solr distribution version
1. Configure [Querqy query parser in `solrconfig.xml`](blob/main/rootfs/opt/solr/server/solr/querqy/conf/solrconfig.xml#L76-L79)
1. Configure [Querqy rule replication in `solrconfig.xml`](blob/main/rootfs/opt/solr/server/solr/querqy/conf/solrconfig.xml#L88)

## 🏃 Up and running

The example launches a local leader/follower Solr example in Docker and configures
Querqy for rewriter rule replication.

#### 1. Build the Docker image

Build the slightly customized Docker image and launch a Solr leader/follower
ensemble. The leader is reacheable at [localhost:8983](http://localhost:8983),
the follower is reachable at [localhost:8984](http://localhost:8984)

```bash
$ docker build -t querqy-solr .
$ docker-compose up
```

#### 2. Create a core

Create the `querqy` core on both the leader and the follower.

```bash
$ curl "http://localhost:8983/solr/admin/cores?action=CREATE&name=querqy&instanceDir=querqy&config=solrconfig.xml&dataDir=data"
$ curl "http://localhost:8984/solr/admin/cores?action=CREATE&name=querqy&instanceDir=querqy&config=solrconfig.xml&dataDir=data"
```

#### 3. Upload Querqy rewrite rules

Upload a single Querqy rule to the `common_rules` rewriter. The rule adds a
synonym from `dog` to `cat`.

```bash
$ curl -X POST "http://localhost:8983/solr/querqy/querqy/rewriter/common_rules?action=save" \
    --data-binary @querqy-rules.json \
    -H "Content-type:application/json"
```

#### 4. Index some data

Indexes terms out of the [data.csv](data.csv) file.

```bash
$ curl "http://localhost:8983/solr/querqy/update?commit=true" \
    --data-binary @data.csv \
    -H "Content-type:application/csv"
```

#### 5. Verify the response

Verify that our Querqy rule works on both the leader and the follower instance
by searching for `dog`. We expect that both `dog` and `cat` return as a result
(due to the synonym entry).

```bash
$ curl -s "http://localhost:8983/solr/querqy/select?q=dog&qf=title&defType=querqy&querqy.rewriters=common_rules&fl=title" \
    | jq '.response'
{
  "numFound": 2,
  "start": 0,
  "docs": [
    {
      "title": "dog"
    },
    {
      "title": "cat"
    }
  ]
}
```

```bash
$ curl -s "http://localhost:8984/solr/querqy/select?q=dog&qf=title&defType=querqy&querqy.rewriters=common_rules&fl=title" \
    | jq '.response'
{
  "numFound": 2,
  "start": 0,
  "docs": [
    {
      "title": "dog"
    },
    {
      "title": "cat"
    }
  ]
}
```
