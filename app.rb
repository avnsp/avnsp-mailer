require './amqp'
require './email'
require 'json'

class App
  include Amqp
  def start
    subscribe("member.mailer.create", "member.created") do |_, msg|
      plan = msg[:plan]
      email_body = msg
      Email.send("Välkommen till Academian", email_body)
    end
    subscribe("member.mailer.password_reset", "member.reset_password") do |_, msg|
      plan = msg[:plan]
      Email.send "[CloudMQTT] deleted #{plan}", JSON.pretty_generate(msg)
    end
  end
end
app = App.new
trap('INT') { app.stop }
app.start
puts "[INFO] avnsp mailer is listening..."
app.loop
