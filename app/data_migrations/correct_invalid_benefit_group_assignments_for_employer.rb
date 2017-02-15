
require File.join(Rails.root, "lib/mongoid_migration_task")

class CorrectInvalidBenefitGroupAssignmentsForEmployer < MongoidMigrationTask

  def invalid_benefit_group_assignments(census_employee)
    census_employee.benefit_group_assignments.select { |bga| ( bga.benefit_group.blank? || bga.start_on < bga.benefit_group.start_on || (bga.end_on.present? && (bga.end_on <  bga.start_on || bga.end_on > bga.benefit_group.end_on)))}
  end
  
  def migrate
    Organization.where(:"employer_profile" => {:$exists => true}).each do |organization|
      organization.employer_profile.census_employees.each do |ce|
        invalid_benefit_group_assignments(ce).each do |bga|
          if bga.benefit_group.present?
            if bga.start_on < bga.benefit_group.start_on
              bga.update_attribute(:start_on, [bga.benefit_group.start_on, ce.hired_on].compact.max)
              puts "Updating the start date of benefit group assignment for #{ce.first_name} #{ce.last_name} for ER with legal name #{organization.legal_name}" unless Rails.env.test?
            end
            if bga.end_on.present? && ( bga.end_on > bga.benefit_group.end_on || bga.end_on <  bga.start_on)
              bga.update_attribute(:end_on, bga.benefit_group.end_on)
              puts "Updating the end date of benefit group assignment for #{ce.first_name} #{ce.last_name} for ER with legal name #{organization.legal_name}" unless Rails.env.test?
            end
          else
            bga.delete if bga.benefit_group.blank?
            puts "Deleting invalid benefit group assignments for #{ce.first_name} #{ce.last_name} for ER with legal name #{organization.legal_name}" unless Rails.env.test?
          end
        end
      end
    end
  end
end
