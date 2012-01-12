Tabloid allows the creation of cacheable report data using a straightforward DSL and output to HTML, CSV, and more to come.

This gem comes out of an Austin.rb meeting about our favorite gems where I sketched out what my ideal reporting DSL would look like.  This gem is inspired by some of the features of Ruport, but I found its API to be a bit top-heavy for rapidly producing reports (though at the time of this writing, Ruport is far more flexible than Tabloid) and its up to you to take care of items like data caching. If your reporting needs are fairly straightforward, Tabloid should work pretty well for your needs.  That said, this gem is early in development and has a lot of rough edges (see TODO list below), but it is being used in production and makes me happy there.

Features:
  * easy to use DSL for specifying report definitions
  * built-in caching of compiled data to Memcached and Redis
  * parameterized reports
  * can be used with your choice of ORM (used in production with ActiveRecord, should be usable with any other ORM)
  * grouping of data with group and report summaries (totals only at the moment)
  * unicorns

How to use it
  
Simple report
  class UnpaidInvoicesReport
    include Tabloid::Report

    element :invoice_number, "Invoice Number"
    element :invoice_date, "Invoice Date"
    element :customer_name, "Name"
    element :invoice_amount, "Amount"
    element :balance, "Balance"

    rows do
      Invoice.select(:invoice_number, :invoice_date, :customer_name, :invoice_amount, :balance).where("balance > 0")
    end
  end

  #create the report
  report = UnpaidInvoicesReport.new

  #collect the data
  report.prepare

  #output formats supported now
  csv = report.to_csv
  html = report.to_html
  pdf = report.to_html


Walking through the above:

  include Tabloid::Report

makes this class into a Tabloid report.

  element :invoice_number, "Invoice Number"

#element creates a report column.  In this case the report data will either use the first element of an array or whatever responds to the symbol :invoice_number on the data coming back from #rows.  More on that in a sec...

    rows do
      Invoice.select(:invoice_number, :invoice_date, :customer_name, :invoice_amount, :balance).where("balance > 0")
    end
  
#rows is the workhorse of a report.  This is where you collect your data for reporting.  It should return an array of arrays or an array of objects that respond to the keys dictated by your use of #element.  (Support for an array of hashes is on the TODO list.) If you use nested arrays, the elements are order dependent—use the order you specified when adding element columns.

#to_csv and #to_html do pretty much what you'd think; they return a string containing the report in the respective formats.  The HTML returned by #to_html is a table with one column per visible column; each cell will have the element symbol as a class name to allow for styling of columns.

Bells and whistles
Tabloid also supports groups with summaries and a report summary.  Only totals and cardinality are supported at the moment, but more flexibility is coming soon.
Tabloid also supports column formatters.

  class UnpaidInvoicesReport < ActiveRecord::Base
    include Tabloid::Report
    handle_asynchronously :prepare

    cache_key { "unpaid_invoices_report-#{id}"}

    #parameterized report, supply parameters to report.prepare(...)
    parameter :start_date
    parameter :end_date

    grouping :customer_name, :total => true, :cardinality => 'invoice'

    element :invoice_number, "Invoice Number"
    element :invoice_date, "Invoice Date", :formatter => lambda { |data| data.strftime "%d %m %Y" }
    element :customer_name, "Name", :hidden => true
    element :invoice_amount, "Amount", :total => true
    element :balance, "Balance"

    summary :balance => :sum

    rows do
      Invoice.select(:invoice_number, :invoice_date, :customer_name, :invoice_amount, :balance).where("balance > 0 AND invoice_date BETWEEN ? AND ?", parameter(:start_date), parameter(:end_date))
    end
  end

There's several things different about this one.  We use #grouping to tell Tabloid to group the data by customer name, and indicate that we want totals to be calculated for each group.  We indicate which columns we want totalled by passing :total => true on the elements requiring totals.  We tell Tabloid to hide the :customer_name column because it will show a group header that contains this element for us.  Finally, we tell Tabloid to summarize the report by summing balances. (:sum is the only accepted value for now, but support is coming for arbitrary blocks and a wider range of built-in functions). We tell Tabloid to add cardinality info (in the example above it might be "42 invoices") for each group and to a report summary. We tell tabloid to customize label(e.g. show payment.payer.name instead payment_id when grouping by payment_id (show 'Some Payer' instead of '345')).

Background support
Notice the parent class on this one? This report is backed by ActiveRecord. The main reason you'd want to do that is to allow for generation of report data in the background.  In the report above, we've enabled that by making #prepare (which invokes the #rows block) run in the background using DelayedJob's #handle_asynchronously method.  To use it under these circumstances, you'll create and save the report, then call prepare explicitly:
   
  report = UnpaidInvoicesReport.create
  report.prepare(:start_date => 30.days.ago, :end_date => Date.today)

Caching support
Background generation of data wouldn't make sense to do, however, unless you were also caching the data somewhere.  Tabloid has explicit support for caching using Memcached and Redis.  Redis is preferred under most circumstances, as it doesn't have the 1MB record limit of memcached.  To enable caching, you have to provide the #cache_key block above (see TODO for changes that are coming there) and set the caching parameters of Tabloid in an initializer:

  #config/initializers/tabloid.rb
  config = YAML.load(IO.read(Rails.root.join("config/tabloid.yml")))[Rails.env]
  if config
    Tabloid.cache_engine             = config['cache_engine'].to_sym
    Tabloid.cache_connection_options = {
        :server => config['server'],
        :port   => config['port']
    }
  end

  #config/tabloid.yml
  production:
    cache_engine: redis
    server: 172.16.0.10
    port: 6379
  development:
    cache_engine: memcached
    server: localhost
    port: 11211
  test:
    cache_engine: memcached
    server: localhost
    port: 11211


Caveat Emptor
This gem is being used in production without any real problems.  There are definitely some rough edges to it; it was born out of the needs of a particular application, so while I've designed it to be something that isn't single purpose, its also geared towards basic reports that have totals in various configurations.  So its a work in progress.  That said, if you need to whip up a report quickly, give it a try.  It has very few dependencies, as its being used with a Rails 2.3 application, so it doesn't pull in anything like ActiveSupport that would make it unsuitable for other environments.

Patches are welcome!

TODO:
* Add more options for summary rows, like average and arbitrary blocks
* clean up the test suite a bit
* documentation!
* more caching mechanisms
* better callbacks
* PDF output format support with PDFkit (optional)
* extend the summary method to support more complex summary formats
* Add support for a preamble section (e.g. detailing report parameters)

