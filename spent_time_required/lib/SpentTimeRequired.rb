module SpentTimeRequired
    module Patches
        module IssuesControllerPatch
            def self.included(base)
                base.extend(ClassMethods)
                base.send(:include, InstanceMethods)
                base.class_eval do
                    unloadable
                    alias_method_chain :update, :check_spent_time
                end
            end

            module ClassMethods
            end

            module InstanceMethods
                def update_with_check_spent_time

                    @check = false
                    @check_trackers = false
                    @check_projects = false

                    begin
                        if (params.has_key?(:time_entry))
                            @status = IssueStatus.find(params[:issue][:status_id])
                            @tracker_id = params[:issue][:tracker_id]
                            @project_id = params[:issue][:project_id]
                            @settings = Setting.plugin_spent_time_required
                            @check = ( \
                                @settings[:all_statuses] \
                            or \
                            ( \
                                @settings[:all_closed_statuses] \
                                and \
                                @status.is_closed? \
                            ) \
                            or \
                            ( \
                                @settings[:list_status].has_key?(@status.id.to_s) \
                                and \
                                @settings[:list_status][@status.id.to_s].to_i == 1 \
                            ) \
                            )
                            @check_projects = @settings[:list_project].has_key?(@project_id)
                            @check_trackers = @settings[:list_tracker].has_key?(@tracker_id) \

                        end

                        if (@check and @check_trackers and @check_projects and params[:time_entry][:hours] == "")
                            flash[:error] = @settings[:required_msg]
                            find_issue
                            update_issue_from_params
                            render(:action => 'edit') and return
                        end

                        update_without_check_spent_time
                    rescue
                        update_without_check_spent_time
                    end
                end
            end
        end
    end
end
