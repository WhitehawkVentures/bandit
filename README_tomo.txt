Development Environment
-----------------------
For development:

1. In the Gemfile, for development purposes comment this line:

     gem "bandit", :git => "git@github.com:WhitehawkVentures/bandit.git"

   and use the local filesystem version:

     gem "bandit", :path => '/Users/jay/WhitehawkVentures/bandit'

   Then run:

     bundle install

   BE SURE TO REVERT TO THE Gemfile THAT USES THE GITHUB GEM BEFORE COMMIT.

2. Get Redis running locally.  To verify redis-server is running:

     redis-cli ping

   Check config at:

     /opt/local/etc/redis.conf

3. Get ImageMagick running locally.

4. Run delayed_jobs:

     for i in 1 2 3 4 5 6 7 8 9 10; do bundle exec rake jobs:work & done

5. Run a sanity test:

     1. Find a sale on the user site:
          http://www.touchofmodern.local:3000/sales
        and in the console:
          stellavie_sale = Sale.where(["name LIKE ?", "%Stellavie%"]).last
          stellavie_sale.id
          stellavie_sale.sale_photos.size

     2. Find that sale on the admin site:
          http://admin.touchofmodern.local:3000/sales?name=Stellavie

     3. Click the "Edit" button and see if it has multiple photos.
        Add 2 new photos with the "Add Photo" button then "Submit".

     4. Verify that the experiment is not yet in Redis:
          redis-cli
          > smembers experiments

     5. Click on the sale in the user site.  
        This should create an experiment.

     6. Verify that the experiment now is in Redis and operational:
          redis-cli
          > smembers experiments
          > KEYS *sale_3519*
          > GET conversions:sale_3519_photo:6:pageview
          # Click the link again and look for increment
          > GET conversions:sale_3519_photo:6:pageview



Issues
------
Bandit instances to run simultaneously on multiple servers, so it is
necessary to use a common data store in order to have a consistent data set
for the lifetime of the data.  For our backing store we use Redis with
persistence, but Bandit supports other storage options, including storage
options without persistence.

Our implementation needs persistence because...

Bandit's currently handles an inability to contact Redis by switching to
memory storage.  The idea is that it keeps using (server local) memory
storage for 5 minutes and then tries Redis again; need to read the code more
closely to see if it actually does that.  It looks like it's not trying to
update Redis once it contact with Redis resumes, which is better than the
alternative of updating Redis with memory counters.  (Server local memory
storage seems like an odd fallback; once the common data store is
inaccessible, tracking individual counters per server is useless and
misleading.  Individual servers could maintain an in-memory transaction log
that could later be applied to the common data store, but we'd need to
implement that.  Also, we should try Redis more than once every 5 minutes.)

Q: On startup, Bandit should load the state it needs.  Does it?

It would be nice if categories were better organized.  Probably best to get
more implementations in place before deciding how best to do that.
Categories (really conversion categories) are somewhat general, but are
ultimately per-experiment.

