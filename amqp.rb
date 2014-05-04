require 'bunny'
require 'json'
require 'zlib'

module Amqp
  def initialize
    @conn = Bunny.new ENV['CLOUDAMQP_URL'] || 'amqp://guest:guest@localhost/avnsp'
    @conn.start
    @pub_ch = @conn.create_channel
    @consumers = []
  end

  def subscribe(qname, *topics, &blk)
    ch = @conn.create_channel
    ch.prefetch 1
    t = ch.topic 'amq.topic', durable: true
    q = ch.queue qname, durable: true
    topics.each do |topic|
      q.bind(t, routing_key: topic)
    end
    c = q.subscribe(ack: true, block: false) do |delivery, headers, body|
      if delivery.redelivered?
        puts "Redelivered msg, sleeping for a while"
        sleep 5
      end
      begin
        if headers.content_encoding == 'gzip'
          body = StringIO.open(body) do |io|
            gz = Zlib::GzipReader.new(io)
            unzipped = gz.read
            gz.close
            unzipped
          end
        end
        if headers.content_type != 'application/json'
          raise "Unknown content type #{headers.content_type}"
        end
        puts "=> #{delivery.routing_key} #{body} #{headers}"
        data = JSON.parse body, symbolize_names: true

        blk.call delivery.routing_key, data, headers
        ch.acknowledge(delivery.delivery_tag, false)
      rescue => e
        puts "[ERROR] #{qname} failed to processing #{delivery.delivery_tag}: #{e.inspect}"
        puts e.backtrace
        ch.reject(delivery.delivery_tag, true)
        false
      end
    end
    @consumers << c
  end

  def publish(topic, data)
    t = @pub_ch.topic 'amq.topic', durable: true
    t.publish data.to_json, routing_key: topic
  end

  def loop
    sleep 1 until @stopped
    @consumers.each { |c| c.cancel }
    @conn.close
    puts "Stopped"
  end

  def stop
    @stopped = true
    puts "Stopping..."
  end
end
