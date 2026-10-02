namespace :queries do
  desc "Run the four queries against seed data and print their SQL. " \
       "Usage: bin/rails 'queries:demo[provider_email,client_email]'"
  task :demo, [ :provider_email, :client_email ] => :environment do |_, args|
    provider = args[:provider_email] ? Provider.find_by!(email: args[:provider_email]) : Provider.order(:id).first
    client   = args[:client_email]   ? Client.find_by!(email: args[:client_email])     : Client.order(:id).first
    abort "No data found. Run `bin/rails db:seed` first." unless provider && client

    section = ->(title, relation = nil) do
      puts "\n#{title}"
      puts "-" * title.length
      puts "SQL: #{relation.to_sql}" if relation
    end

    clients = provider.clients
    section.("1. All clients for #{provider.name}", clients)
    provider.subscriptions.includes(:client).order(:id).each do |s|
      puts "  #{s.client.name} <#{s.client.email}>  [#{s.plan}]"
    end

    providers = client.providers
    section.("2. All providers for #{client.name}", providers)
    client.subscriptions.includes(:provider).order(:id).each do |s|
      puts "  #{s.provider.name} <#{s.provider.email}>  [#{s.plan}]"
    end

    entries = client.journal_entries.newest_first
    section.("3. Journal entries for #{client.name}, newest first", entries)
    entries.each { |e| puts "  #{e.created_at.to_date}  #{e.body.truncate(60)}" }

    feed = provider.journal_entries.newest_first.includes(:client)
    section.("4. Journal entries across all of #{provider.name}'s clients, newest first", feed)
    feed.each { |e| puts "  #{e.created_at.to_date}  #{e.client.name.ljust(12)} #{e.body.truncate(50)}" }
  end
end
