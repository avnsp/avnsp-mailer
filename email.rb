require 'mail'

Mail.defaults do
  delivery_method :smtp, { 
    :address              => "email-smtp.us-east-1.amazonaws.com",
    :port                 => 587,
    :domain               => "academian.se",
    :user_name            => ENV.fetch('SES_ACCESS_KEY'),
    :password             => ENV.fetch('SES_SECRET_KEY'),
    :authentication       => 'plain',
    :enable_starttls_auto => true
  }
end

class Email
  def self.send to, sub, body
    Mail.deliver do
      from    'auth@academian.se'
      to      to
      subject sub
      body    body
    end 
  end
end
