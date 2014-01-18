class Bandit::DashboardController < Bandit::ApplicationController
  respond_to :html, :csv

  def index
    @experiments = Bandit.experiments
  end

  def show
    @experiment = Bandit.get_experiment params[:id].intern
    respond_to do |format|
      format.html
      format.csv { render :text => experiment_csv(@experiment, params[:category]) }
    end
  end

  private
  def experiment_csv(experiment, category)
    rows = []
    experiment.alternatives.each do |alt|
      start = experiment.alternative_start(alt)
      next if start.nil?
      start.date.upto(Date.today) do |d|
        Bandit::DateHour.new(d, 0).upto(Bandit::DateHour.new(d, 23)) { |dh|
          #initial = yield initial, dh
          pcount = experiment.participant_count(alt, dh)
          ccount = experiment.conversion_count(alt, category, dh)
          rows << [ alt, d.year, d.month, d.day, dh.hour, pcount, ccount ].join("\t")
        }
      end
    end
    rows.join("\n")
  end
end
