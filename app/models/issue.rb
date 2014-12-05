# == Schema Information
#
# Table name: issues
#
#  id            :integer          not null, primary key
#  github_url    :string(255)      not null
#  number        :integer          not null
#  open          :boolean          not null
#  title         :string(255)      default("Untitled"), not null
#  issuer_id     :integer          not null
#  repository_id :integer          not null
#  labels        :text             default("--- []\n"), not null
#  body          :text
#  assignee_id   :integer
#  milestone     :string(255)
#  created_at    :datetime
#  updated_at    :datetime
#

class Issue < ActiveRecord::Base
  belongs_to :issuer,   class_name: :Coder,
                        inverse_of: :created_issues,
                        foreign_key: 'issuer_id'
  belongs_to :assignee, inverse_of: :assigned_issues, 
                        class_name: 'Coder'
  belongs_to :repository
  has_many :bounties

  serialize :labels

  def find_bounty_by_coder coder
    bounty = bounties.where(coder: coder).first
    bounty.present? ? bounty : bounties.build(value: 0)
  end

  def total_bounty_value
    bounties.map {|b| b.absolute_value}.sum
  end

  def close
    bounties.each { |b| b.cash_in }
    update! open: false
    save!
  end

  def self.find_or_create_from_hash json, repo
    Issue.find_or_create_by number: json['number'],
                            repository: repo do |issue|
      issue.github_url = json['html_url']
      issue.number     = json['number']
      issue.open       = json['state'] == 'open'
      issue.title      = json['title']
      issue.body       = json['body']
      issue.issuer     = Coder.find_or_create_by_github_name(json['user']['login'])
      issue.labels     = (json['labels'] || []).map  { |label| label.name }
      issue.milestone  = json['milestone'].try(:[], :title)

      unless json['assignee'].blank?
        issue.assignee =
          Coder.find_or_create_by_github_name(json['assignee']['login'])
      end
    end
  end
end
