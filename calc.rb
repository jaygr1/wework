require 'pry'
require 'csv'
require 'date'

class Calc

  COMMON_YEAR_DAYS_IN_MONTH = [nil, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
  LEAP_YEAR_DAYS_IN_MONTH = [nil, 31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

  def rentals
    file = ('data.csv')
    keywords = File.readlines(file)
    headers = keywords.shift
    keywords = keywords.map do |line|
      line = line.split(",")
      line = {
        capacity: line[0], monthlyprice: line[1], startday: line[2], endday: line[3]
      }
    end
  end

  def leap_year(date)
    given_date = Date.strptime(date,'%Y-%m')
    year = given_date.year
    Date.gregorian_leap?(year)
  end

  def days_in_month(date)
    first = Date.strptime(date,'%Y-%m')
    if leap_year(date)
      return days_in_month = LEAP_YEAR_DAYS_IN_MONTH[first.mon]
    else
      return days_in_month = COMMON_YEAR_DAYS_IN_MONTH[first.mon]
    end
  end

  def month(date)
    first = Date.strptime(date,'%Y-%m')
    days_in_month(date)
    last = Date.new(first.year, first.mon, days_in_month(date))
    range = (first..last)
  end

  def find_booked_offices(date)
    booked = Array.new
    rentals.map do |rental|
      if rental[:endday] == "\n" && ((Date.strptime(rental[:startday]) < month(date).first))
        booked.push(rental)
      elsif rental[:endday].chomp.length == 10 && ((Date.strptime(rental[:startday]) - month(date).last) * (month(date).first - Date.parse(rental[:endday]))) >= 0
        booked.push(rental)
      end
    end
    booked
  end

  def expected_revenue(date)
    fees = Array.new
    rentals.map do |rental|
      if rental[:endday] == "\n" && Date.strptime(rental[:startday]) <= month(date).first
        fees.push(rental[:monthlyprice].to_i)
      elsif rental[:endday] == "\n" && Date.strptime(rental[:startday]) <= month(date).last
        mid_month_start_revenue = (((((days_in_month(date) - Date.strptime(rental[:startday]).mday.to_f)) / days_in_month(date))) * rental[:monthlyprice].to_f)
        fees.push(mid_month_start_revenue)
      elsif rental[:endday].chomp.length == 10 && Date.strptime(rental[:startday]) <= month(date).first && Date.strptime(rental[:endday]) >= month(date).last
        fees.push(rental[:monthlyprice].to_i)
      elsif rental[:endday].chomp.length == 10 && Date.strptime(rental[:startday]) <= month(date).first && Date.strptime((rental[:endday].chomp)) < month(date).last && ((Date.strptime(rental[:startday]) - month(date).last) * (month(date).first - Date.parse(rental[:endday]))) >= 0
        pro_rated_revenue = (((((days_in_month(date) - Date.strptime(rental[:endday]).mday.to_f)) / days_in_month(date))) * rental[:monthlyprice].to_f)
        fees.push(pro_rated_revenue)
      elsif rental[:endday].chomp.length == 10 && Date.strptime(rental[:startday]) <= month(date).last && Date.strptime(rental[:endday]) >= month(date).last
        binding.pry
        pro_rated_revenue = (((((days_in_month(date) - Date.strptime(rental[:startday]).mday.to_f)) / days_in_month(date))) * rental[:monthlyprice].to_f)
        fees.push(pro_rated_revenue)
      end
    end
    fees
  end

  def is_number?(string)
    true if Float(string) rescue false
  end

  def total_capacity
    capacity = Array.new
    rentals.map do |rental|
      if is_number?(rental[:capacity])
        capacity << rental[:capacity].to_i
      end
    end
    value = capacity.inject {|sum, n| sum += n}
  end

  def reserved_capacity(date)
    reserved_office_count = find_booked_offices(date).map do |office|
      office[:capacity].to_i
    end
    reserved_office_count.inject {|sum, n| sum += n}
  end

  def unreserved_offices(date)
    if reserved_capacity(date) == nil
      total_capacity
    else
      total_capacity - reserved_capacity(date)
    end
  end

  def evaluate(date)
    income = expected_revenue(date).inject{|sum,x| sum + x }
    if income == nil
      format_income = '0.00'
      return "expected revenue: $#{format_income}, total capacity of unreserved offices: #{unreserved_offices(date)}"
    end
    income_string = income.round(2).to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
    puts "expected revenue: $#{income_string}, total capacity of unreserved offices: #{unreserved_offices(date)}"
  end
end

stuff = Calc.new
stuff.evaluate('2018-01')