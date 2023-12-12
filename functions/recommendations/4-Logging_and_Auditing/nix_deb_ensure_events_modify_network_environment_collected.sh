#!/usr/bin/env bash
#
# CIS-LBK Recommendation Function
# ~/CIS-LBK/functions/recommendations/nix_deb_ensure_events_modify_network_environment_collected.sh
# 
# Name                Date       Description
# ------------------------------------------------------------------------------------------------
# J. Brown	         01/26/23    Recommendation "Ensure events that modify the system's network environment are collected"
# 

deb_ensure_events_modify_network_environment_collected()
{
	echo
	echo -e "\n**************************************************\n- $(date +%d-%b-%Y' '%T)\n- Start Recommendation \"$RN - $RNA\"" | tee -a "$LOG" 2>> "$ELOG"
	l_test=""
	l_uid_min=""

	# Collect UID_MIN value
	l_uid_min="$(awk '/^\s*UID_MIN/{print $2}' /etc/login.defs)"
	if [ -z "$uid_min" ]; then
		uid_min=1000
	fi

	# Verify if auditd rules can be loaded
	check_audit_rule_loadable(){
		if [[ $(auditctl -s | grep "enabled") =~ "2" ]]; then
			G_AUDITD_IMMUTABLE="yes"
			G_REBOOT_REQUIRED="yes"
		fi
	}

	# Collect the ondisk auditd rules containing -F arch=
	# Expects 1 parameters "arch"
	# Example find_ondisk_rule_arch "b32"
	find_ondisk_rule_arch(){
		grep -Pih -- "-a\h+(always,exit|exit,always)\h.*-F\h$1" /etc/audit/rules.d/*.rules
	}

	# Collect the ondisk auditd rules not containing -F arch=
	# Example find_ondisk_rule_no_arch
	find_ondisk_rule_no_arch(){
		grep -Pih -- "-a\h+(always,exit|exit,always)\h" /etc/audit/rules.d/*.rules | grep -Pv -- "-F arch="
	}

	# Collect the loaded auditd rules containing -F arch=
	# Expects 1 parameters "arch"
	# Example find_auditctl_rule_arch "b32"
	find_auditctl_rule_arch(){
		auditctl -l | grep -Pi -- "-a\h+(always,exit|exit,always)\h.*-F\h$1"
	}

	# Collect the loaded auditd rules not containing -F arch=
	# Example find_auditctl_rule_no_arch
	find_auditctl_rule_no_arch(){
		auditctl -l | grep -Pi -- "-a\h+(always,exit|exit,always)\h" | grep -Pv -- "-F arch="
	}

	# Collect the ondisk auditd watcher rules containing -w <file>
	# Example find_ondisk_rule_watcher
	find_ondisk_rule_watcher(){
		grep -Pih -- "-w\h+[/\S]+" /etc/audit/rules.d/*.rules
	}

	# Collect the loaded auditd rules watcher rules containing -w <file>
	# Example find_auditctl_rule_watcher
	find_auditctl_rule_watcher(){
		auditctl -l | grep -Pi -- "-w\h+[/\S]+"
	}

	# Expects 4 parameters "arch=|noarch" "ondisk|auditctl" "calls" "parameters"
	# Example eval_auditd_syscall_rule "arch=b64" "ondisk" "l_calls" "l_parameters"
	# l_calls MUST be a comma separated list like "call1,call2,call3"
	# l_parameters MUST be a semi-colon separated list parameters and each parameter MUST be a colon sparated pair of <value>:<regex for value> like "val1=a:val1\s*=\s*[Aa];val2=b:val2\s*=\s*[Bb]"
	eval_auditd_syscall_rule(){
		arch="$1" type="$2" calls_in="$3" parameters_in="$4"

        # Clear instance vars
        unset ruleset_all
        unset ruleset_array
        unset exp_calls_array
        unset exp_parameters_array
        unset rules_found_array
        unset calls_found_array
        unset parameters_found_array
        unset missing_parameter_array

        # Collect candidate rules
		case "$type:$arch" in
			ondisk:arch=*)
				ruleset_all="$(find_ondisk_rule_arch "$arch")"
				;;
			ondisk:noarch)
				ruleset_all="$(find_ondisk_rule_no_arch)"
				;;
			auditctl:arch=*)
				ruleset_all="$(find_auditctl_rule_arch "$arch")"
				;;
			auditctl:noarch)
				ruleset_all="$(find_auditctl_rule_no_arch)"
				;;
		esac

        # Create array of candidate rules
        declare -a ruleset_array
        while rule= read -r ruleset_entry; do
            ruleset_array+=("$ruleset_entry")
        done <<< "$ruleset_all"

        # Create array of required calls
        declare -a exp_calls_array
        while calls= read -r call_entry; do
            exp_calls_array+=("$call_entry")
        done <<< "$(echo -e "$calls_in" | tr ',' '\n')"

        # Create array of required parameters
        declare -a exp_parameters_array
        while parameters= read -r parameter_entry; do
            exp_parameters_array+=("$parameter_entry")
        done <<< "$(echo -e "$parameters_in" | tr ';' '\n')"

        # Find rules that contain expected calls
        declare -a rules_found_array
        declare -a calls_found_array
        for rule in "${ruleset_array[@]}"; do
            for exp_call in "${exp_calls_array[@]}"; do
                if grep -Pq -- "-S(\h|\h[\S_]+,)?\b$exp_call\b" <<< "$rule"; then
                    if ! printf '%s\0' "${rules_found_array[@]}" | grep -Fxqz -- "$rule"; then
						rules_found_array+=("$rule")
					fi
                    calls_found_array+=("$exp_call")
                fi
            done
        done

        # Create the list of missing calls
        for call in "${exp_calls_array[@]}"; do
            if ! printf '%s\0' "${calls_found_array[@]}" | grep -Fxqz -- "$call"; then
                l_output2="$l_output2\n- No $arch $type rules entry for: $call"
            fi
        done

        # Create list of missing parameters in the found rules
        for rule in "${rules_found_array[@]}"; do
            # Clean up arrays
            unset parameters_found_array
            unset missing_parameter_array
            declare -a parameters_found_array
            for parameter in "${exp_parameters_array[@]}"; do
                test_parameter="$(awk -F: '{print $2}' <<< "$parameter")"
                if grep -Pq -- "$test_parameter" <<< "$rule"; then
                    if ! printf '%s\0' "${parameters_found_array[@]}" | grep -Fxqz -- "$parameter"; then
                        parameters_found_array+=("$parameter")
                    fi
                fi
            done

            # Create the list of missing parameters
            declare -a missing_parameter_array
            for parameter in "${exp_parameters_array[@]}"; do
                if ! printf '%s\0' "${parameters_found_array[@]}" | grep -Fxqz -- "$parameter"; then
                    missing_parameter_array+=("$parameter")
                fi
            done

            if (( ${#missing_parameter_array[@]} > 0 )); then
                l_output2="$l_output2\n- $type Rule:\"$rule\" missing required parameters"
            else
                l_output="$l_output\n- $type Rule:\"$rule\" correctly configured"
            fi
        done
	}

	# Expects 5 parameters "arch|noarch" "calls" "parameters" "key" "rules_file"
	# Example fix_auditd_syscall_rule "arch=b64" "l_calls" "l_parameters" "kernel" "/etc/audit/rules.d/50-kernel_modules.rules"
	# l_calls MUST be a comma separated list like "call1,call2,call3"
	# l_parameters MUST be a semi-colon separated list parameters and each parameter MUST be a colon sparated pair of <value>:<regex for value> like "val1=a:val1\s*=\s*[Aa];val2=b:val2\s*=\s*[Bb]"
	fix_auditd_syscall_rule(){
        arch="$1" calls_in="$2" parameters_in="$3" key="$4" rule_file="$5"

        # Clear instance vars
        unset ruleset_all
        unset ruleset_array
        unset exp_calls_array
        unset exp_parameters_array
        unset rules_found_array
        unset calls_found_array
        unset parameters_found_array
        unset missing_parameter_array
        
        case "$arch" in
			arch=*)
				ruleset_all="$(find_ondisk_rule_arch "$arch")"
				;;
			noarch)
				ruleset_all="$(find_ondisk_rule_no_arch)"
				;;
		esac

        # Create array of candidate rules
        declare -a ruleset_array
        while rule= read -r ruleset_entry; do
            ruleset_array+=("$ruleset_entry")
        done <<< "$ruleset_all"

        # Determine if auditd rules are loadable without a reboot
		if [ -z "$G_AUDITD_IMMUTABLE" ] || [ -z "$G_REBOOT_REQUIRED" ]; then
			check_audit_rule_loadable
		fi

        # Create array of required calls
        declare -a exp_calls_array
        while calls= read -r call_entry; do
            exp_calls_array+=("$call_entry")
        done <<< "$(echo -e "$calls_in" | tr ',' '\n')"

        # Create array of required parameters
        declare -a exp_parameters_array
        while parameters= read -r parameter_entry; do
            exp_parameters_array+=("$parameter_entry")
        done <<< "$(echo -e "$parameters_in" | tr ';' '\n')"

        # Find rules that contain expected calls
        declare -a rules_found_array
        declare -a calls_found_array
        for rule in "${ruleset_array[@]}"; do
            for exp_call in "${exp_calls_array[@]}"; do
                if grep -Pq -- "-S(\h|\h[\S_]+,)?\b$exp_call\b" <<< "$rule"; then
 					if ! printf '%s\0' "${rules_found_array[@]}" | grep -Fxqz -- "$rule"; then
						rules_found_array+=("$rule")
					fi
                    calls_found_array+=("$exp_call")
                fi
            done
        done

		# Create the list of missing calls
        for call in "${exp_calls_array[@]}"; do
            if ! printf '%s\0' "${calls_found_array[@]}" | grep -Fxqz -- "$call"; then
                echo -e "-  Inserting $arch rule for $call" | tee -a "$LOG" 2>> "$ELOG"
                # Create list of params to insert
                parameter_insert_list=""
                for parameter in "${exp_parameters_array[@]}"; do
                     parameter_insert="$(echo "$parameter" | awk -F: '{print $1}')"
                     if [ -z "$parameter_insert_list" ]; then
						parameter_insert_list="$parameter_insert"
					else
						parameter_insert_list="$parameter_insert_list $parameter_insert"
					fi
                done

                if [ "$arch" != "noarch" ]; then
                    echo -e "- Rule to be inserted: \"-a always,exit -F $arch -S $call $parameter_insert_list -k $key\"" | tee -a "$LOG" 2>> "$ELOG"
					echo "-a always,exit -F $arch -S $call $parameter_insert_list -k $key" >> "$rule_file"
				else
                    echo -e "- Rule to be inserted: \"-a always,exit -S $call $parameter_insert_list -k $key\"" | tee -a "$LOG" 2>> "$ELOG"
					echo "-a always,exit -S $call $parameter_insert_list -k $key" >> "$rule_file"
				fi
            fi
        done

        # Create list of missing parameters in the found rules
        for rule in "${rules_found_array[@]}"; do
            # Clean up arrays
            unset parameters_found_array
            unset missing_parameter_array
            declare -a parameters_found_array
            for parameter in "${exp_parameters_array[@]}"; do
                test_parameter="$(awk -F: '{print $2}' <<< "$parameter")"
                if grep -Pq -- "$test_parameter" <<< "$rule"; then
                    if ! printf '%s\0' "${parameters_found_array[@]}" | grep -Fxqz -- "$parameter"; then
                        parameters_found_array+=("$parameter")
                    fi
                fi
            done

            # Create the list of missing parameters
            declare -a missing_parameter_array
            for parameter in "${exp_parameters_array[@]}"; do
                if ! printf '%s\0' "${parameters_found_array[@]}" | grep -Fxqz -- "$parameter"; then
                    missing_parameter_array+=("$parameter")
                fi
            done

            if (( ${#missing_parameter_array[@]} > 0 )); then
                parameter_insert_list=""
                rule_file="$(grep -Pil -- "$rule" /etc/audit/rules.d/*.rules)"
                rule_line="$(grep -Pihn -- "$rule" /etc/audit/rules.d/*.rules | awk -F':' '{print $1}')"

                echo -e "-  Updating parameters in $arch rule \"$rule\" in $rule_file" | tee -a "$LOG" 2>> "$ELOG"
                for parameter in "${missing_parameter_array[@]}"; do
                    parameter_insert="$(echo "$parameter" | awk -F: '{print $1}')"
                    if [ -z "$parameter_insert_list" ]; then
						parameter_insert_list="$parameter_insert"
					else
						parameter_insert_list="$parameter_insert_list $parameter_insert"
					fi
                done

                rule_line_regex="$(grep -Po -- '^.+-S\s([\S+,])?\S+\b' <<< "$rule")"
                echo -e "-   Adding $parameter_insert_list" | tee -a "$LOG" 2>> "$ELOG"
                sed -ri "$rule_line s/($rule_line_regex)(.*)$/\1 $parameter_insert_list\2/" "$rule_file"
            fi
        done

		# If rules are loadable; load them
		if [ "$G_AUDITD_IMMUTABLE" != "yes" ]; then
			echo "- Running 'augenrules --load' to load updated rules" | tee -a "$LOG" 2>> "$ELOG"
			augenrules --load > /dev/null 2>&1
		fi
	}

    # Expects 3 parameters "ondisk|auditctl" "file" "permissions"
	# Example eval_auditd_watcher_rule "ondisk" "l_files" "l_permissions"
	# l_files MUST be a comma separated list like "/var/log/lastlog,/var/run/faillock"
	# l_permissions MUST be a semi-colon separated list of -p permissions (r,w,x or a)"
	eval_auditd_watcher_rule(){
		type="$1" files_in="$2" permissions_in="$3"

		# Clear instance vars
        unset ruleset_all
        unset ruleset_array
        unset exp_files_array
        unset exp_permissions_array
        unset rules_found_array
        unset files_found_array
        unset missing_files_array
        unset permissions_found_array
        unset missing_permissions_array

		case "$type" in
			ondisk)
				ruleset_all="$(find_ondisk_rule_watcher)"
				;;
			auditctl)
				ruleset_all="$(find_auditctl_rule_watcher)"
				;;
		esac

		# Create array of candidate rules
        declare -a ruleset_array
        while rule= read -r ruleset_entry; do
            ruleset_array+=("$ruleset_entry")
        done <<< "$ruleset_all"

		# Create array of required files
        declare -a exp_files_array
        while file= read -r file_entry; do
            exp_files_array+=("$file_entry")
        done <<< "$(echo -e "$files_in" | tr ',' '\n')"

		# Create array of required permissions
        declare -a exp_permissions_array
        while permissions= read -r permission_entry; do
            exp_permissions_array+=("$permission_entry")
        done <<< "$(echo -e "$permissions_in" | tr ';' '\n')"

		# Find rules that contain expected files
        declare -a rules_found_array
        declare -a files_found_array
        for rule in "${ruleset_array[@]}"; do
            for exp_file in "${exp_files_array[@]}"; do
                if grep -Pq -- "-w\s+$(sed 's/\//\\\//g' <<< "$exp_file")" <<< "$rule"; then
                    if ! printf '%s\0' "${rules_found_array[@]}" | grep -Fxqz -- "$rule"; then
						rules_found_array+=("$rule")
					fi
                    files_found_array+=("$exp_file")
                fi
            done
        done

		# Create the list of missing files
        for file in "${exp_files_array[@]}"; do
            if ! printf '%s\0' "${files_found_array[@]}" | grep -Fxqz -- "$file"; then
                l_output2="$l_output2\n- No $type rules entry for: $file"
            fi
        done

		# Create list of missing parameters in the found rules
        for rule in "${rules_found_array[@]}"; do
            # Clean up arrays
            unset permissions_found_array
            unset missing_permissions_array
            declare -a permissions_found_array
            for permission in "${exp_permissions_array[@]}"; do
                if grep -Pq -- "-p\h+(\S)?$permission" <<< "$rule"; then
                    if ! printf '%s\0' "${permissions_found_array[@]}" | grep -Fxqz -- "$permission"; then
                        permissions_found_array+=("$permission")
                    fi
                fi
            done

			# Create the list of missing parameters
            declare -a missing_permissions_array
            for permission in "${exp_permissions_array[@]}"; do
                if ! printf '%s\0' "${permissions_found_array[@]}" | grep -Fxqz -- "$permission"; then
                    missing_permissions_array+=("$permission")
                fi
            done

            if (( ${#missing_permissions_array[@]} > 0 )); then
                l_output2="$l_output2\n- $type Rule:\"$rule\" missing required permissions"
            else
                l_output="$l_output\n- $type Rule:\"$rule\" correctly configured"
            fi
        done
	}

    # Expects 4 parameters "file" "permissions" "key" "rules_file"
	# Example fix_auditd_watcher_rule "l_files" "l_permissions" "logins" "/etc/audit/rules.d/50-login.rules"
	# l_command MUST be a comma separated list like "/var/log/lastlog,/var/run/faillock" (Normally this is only a single value)
	# l_permissions MUST be a semi-colon separated list of -p permissions (r,w,x or a)"
	fix_auditd_watcher_rule(){
		files_in="$1" permissions_in="$2" key="$3" rule_file="$4"

        # Clear instance vars
        unset ruleset_all
        unset ruleset_array
        unset exp_files_array
        unset exp_permissions_array
        unset rules_found_array
        unset files_found_array
        unset permissions_found_array
        unset missing_permission_array

        # Collect candidate rules
		ruleset_all="$(find_ondisk_rule_watcher)"
		
		# Create array of candidate rules
        declare -a ruleset_array
        while rule= read -r ruleset_entry; do
            ruleset_array+=("$ruleset_entry")
        done <<< "$ruleset_all"

		# Create array of required files
        declare -a exp_files_array
        while file= read -r file_entry; do
            exp_files_array+=("$file_entry")
        done <<< "$(echo -e "$files_in" | tr ',' '\n')"
		
		# Create array of required permissions
        declare -a exp_permissions_array
        while permission= read -r permission_entry; do
            exp_permissions_array+=("$permission_entry")
        done <<< "$(echo -e "$permissions_in" | tr ';' '\n')"

		# Determine if auditd rules are loadable without a reboot
		if [ -z "$G_AUDITD_IMMUTABLE" ] || [ -z "$G_REBOOT_REQUIRED" ]; then
			check_audit_rule_loadable
		fi
		
		# Find rules that contain expected files
        declare -a rules_found_array
        declare -a files_found_array
        for rule in "${ruleset_array[@]}"; do
            for file in "${exp_files_array[@]}"; do
                if grep -Pq -- "-w\s+$(sed 's/\//\\\//g' <<< "$file")" <<< "$rule"; then
                    if ! printf '%s\0' "${rules_found_array[@]}" | grep -Fxqz -- "$rule"; then
						rules_found_array+=("$rule")
					fi
                    files_found_array+=("$file")
                fi
            done
        done

		# Create the list of missing files
        for file in "${exp_files_array[@]}"; do
            if ! printf '%s\0' "${files_found_array[@]}" | grep -Fxqz -- "$file"; then
                echo -e "-  Inserting rule for $file" | tee -a "$LOG" 2>> "$ELOG"
                # Create list of permissions to insert
				permission_insert_list=""
                for permission in "${exp_permissions_array[@]}"; do
                     if [ -z "$permission_insert_list" ]; then
						permission_insert_list="$permission"
					else
						permission_insert_list="$permission_insert_list$permission"
					fi
                done

				echo -e "- Rule to be inserted: \"-w $file -p $permission_insert_list -k $key\"" | tee -a "$LOG" 2>> "$ELOG"
				echo "-w $file -p $permission_insert_list -k $key" >> "$rule_file"
            fi
        done

        # Create list of missing permission in the found rules
        for rule in "${rules_found_array[@]}"; do
            # Clean up arrays
            unset permissions_found_array
            unset missing_permission_array
            declare -a permissions_found_array
            for permission in "${exp_permissions_array[@]}"; do
                if grep -Pq -- "\s-p\s+(\S+)?$permission" <<< "$rule"; then
                    if ! printf '%s\0' "${permissions_found_array[@]}" | grep -Fxqz -- "$permission"; then
                        permissions_found_array+=("$permission")
                    fi
                fi
            done

            # Create the list of missing permissions
            declare -a missing_permission_array
            for permission in "${exp_permissions_array[@]}"; do
                if ! printf '%s\0' "${permissions_found_array[@]}" | grep -Fxqz -- "$permission"; then
                    missing_permission_array+=("$permission")
                fi
            done

            if (( ${#missing_permission_array[@]} > 0 )); then
                permission_insert_list=""
                rule_file="$(grep -Pil -- "$rule" /etc/audit/rules.d/*.rules)"
                rule_line="$(grep -Pihn -- "$rule" /etc/audit/rules.d/*.rules | awk -F':' '{print $1}')"

                echo -e "-  Updating permission in rule \"$rule\" in $rule_file" | tee -a "$LOG" 2>> "$ELOG"
                for permission in "${missing_permission_array[@]}"; do
                    if [ -z "$permission_insert_list" ]; then
						permission_insert_list="$permission"
					else
						permission_insert_list="$permission_insert_list$permission"
					fi
                done

                rule_line_regex="$(grep -Po -- '^.+-p\s(S+)?\S+\b' <<< "$rule")"
                echo -e "-   Adding $permission_insert_list" | tee -a "$LOG" 2>> "$ELOG"
                sed -ri "$rule_line s|($rule_line_regex)(.*)$|\1$permission_insert_list\2|" "$rule_file"
            fi
        done

		# If rules are loadable; load them
		if [ "$G_AUDITD_IMMUTABLE" != "yes" ]; then
			echo "- Running 'augenrules --load' to load updated rules" | tee -a "$LOG" 2>> "$ELOG"
			augenrules --load > /dev/null 2>&1
		fi
	}

	# Check if system is 32 or 64 bit
	arch | grep -q -- "x86_64" && l_sysarch=b64 || l_sysarch=b32

	deb_ensure_events_modify_network_environment_collected_chk()
	{
		echo "- Start check - Ensure events that modify the system's network environment are collected" | tee -a "$LOG" 2>> "$ELOG"
		l_output="" l_output2=""

		# check the rule(s) for sethostname,setdomainname

		# Set the syscalls we're interested in
		l_rule_1="sethostname,setdomainname"
		l_parameters_rule_1=""

        if [ "$l_sysarch" = "b64" ];then
            # Verify b64 ondisk rules
            echo -e "- Checking arch=b64 ondisk rules for sethostname,setdomainname" | tee -a "$LOG" 2>> "$ELOG"
            eval_auditd_syscall_rule "arch=b64" "ondisk" "$l_rule_1" "$l_parameters_rule_1"

            # Verify b64 auditctl entry
            echo -e "- Checking arch=b64 auditctl rules for sethostname,setdomainname" | tee -a "$LOG" 2>> "$ELOG"
            eval_auditd_syscall_rule "arch=b64" "auditctl" "$l_rule_1" "$l_parameters_rule_1"
        fi

        # Verify b32 ondisk rules
        echo -e "- Checking arch=b32 ondisk rules for sethostname,setdomainname" | tee -a "$LOG" 2>> "$ELOG"
        eval_auditd_syscall_rule "arch=b32" "ondisk" "$l_rule_1" "$l_parameters_rule_1"

        # Verify b32 auditctl entry
        echo -e "- Checking arch=b32 auditctl rules for sethostname,setdomainname" | tee -a "$LOG" 2>> "$ELOG"
        eval_auditd_syscall_rule "arch=b32" "auditctl" "$l_rule_1" "$l_parameters_rule_1"

        # check the rule(s) for /etc/issue,/etc/issue.net,/etc/hosts,/etc/networks,/etc/network/

        # Set the files we're interested in
		l_rule_2="/etc/issue,/etc/issue.net,/etc/hosts,/etc/networks,/etc/network"
		l_permissions_rule_2="w;a"

        # Verify ondisk rules
        echo -e "- Checking ondisk rules for /etc/issue,/etc/issue.net,/etc/hosts,/etc/networks,/etc/network" | tee -a "$LOG" 2>> "$ELOG"
        eval_auditd_watcher_rule "ondisk" "$l_rule_2" "$l_permissions_rule_2"

        # Verify auditctl entry
        echo -e "- Checking auditctl rules for /etc/issue,/etc/issue.net,/etc/hosts,/etc/networks,/etc/network" | tee -a "$LOG" 2>> "$ELOG"
        eval_auditd_watcher_rule "auditctl" "$l_rule_2" "$l_permissions_rule_2"

		if [ -z "$l_output2" ]; then
			echo -e "- PASS:\n$l_output\n" | tee -a "$LOG" 2>> "$ELOG"
			echo -e "- End check - Ensure events that modify the system's network environment are collected" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-101}"
		else
			echo -e "- FAIL:\n- Failing values:\n$l_output2\n" | tee -a "$LOG" 2>> "$ELOG"
			if [ -n "$l_output" ]; then
				echo -e "- Passing values:\n$l_output\n" | tee -a "$LOG" 2>> "$ELOG"
			fi
			echo -e "- End check - Ensure events that modify the system's network environment are collected" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_FAIL:-102}"
		fi
	}

	deb_ensure_events_modify_network_environment_collected_fix()
	{
		echo "- Start remediation - Ensure events that modify the system's network environment are collected" | tee -a "$LOG" 2>> "$ELOG"
		
        if [ "$l_sysarch" = "b64" ];then
            # Fix b64 ondisk rules
            echo -e "- Fixing arch=b64 ondisk rules for sethostname,setdomainname" | tee -a "$LOG" 2>> "$ELOG"
            fix_auditd_syscall_rule "arch=b64" "$l_rule_1" "$l_parameters_rule_1" "system-locale" "/etc/audit/rules.d/50-system_local.rules"
        fi

        # Fix b32 ondisk rules
        echo -e "- Fixing arch=b32 ondisk rules for sethostname,setdomainname" | tee -a "$LOG" 2>> "$ELOG"
        fix_auditd_syscall_rule "arch=b32" "$l_rule_1" "$l_parameters_rule_1" "system-locale" "/etc/audit/rules.d/50-system_local.rules"

        # Fix ondisk rules
        echo -e "- Fixing ondisk rules for /etc/issue,/etc/issue.net,/etc/hosts,/etc/networks,/etc/network" | tee -a "$LOG" 2>> "$ELOG"
        fix_auditd_watcher_rule "$l_rule_2" "$l_permissions_rule_2" "system-locale" "/etc/audit/rules.d/50-system_local.rules"
		

		echo "- End remediation - Ensure events that modify the system's network environment are collected" | tee -a "$LOG" 2>> "$ELOG"	
	}

	deb_ensure_events_modify_network_environment_collected_chk
	if [ "$?" = "101" ]; then
		[ -z "$l_test" ] && l_test="passed"
	else
		deb_ensure_events_modify_network_environment_collected_fix
		if [ "$G_AUDITD_IMMUTABLE" != "yes" ]; then
	 		deb_ensure_events_modify_network_environment_collected_chk
			if [ "$?" = "101" ] ; then
				[ "$l_test" != "failed" ] && l_test="remediated"
			else
				l_test="failed"
			fi
		else
			l_test=manual
			echo -e "A manual reboot is REQUIRED to load the updated audit rules."
			return "${XCCDF_RESULT_FAIL:-106}"
		fi
	fi

	# Set return code, end recommendation entry in verbose log, and return
	case "$l_test" in
		passed)
			echo -e "- Result - No remediation required\n- End Recommendation \"$RN - $RNA\"\n**************************************************\n" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-101}"
			;;
		remediated)
			echo -e "- Result - successfully remediated\n- End Recommendation \"$RN - $RNA\"\n**************************************************\n" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-103}"
			;;
		manual)
			echo -e "- Result - requires manual remediation\n- End Recommendation \"$RN - $RNA\"\n**************************************************\n" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_FAIL:-106}"
			;;
		NA)
			echo -e "- Result - Recommendation is non applicable\n- End Recommendation \"$RN - $RNA\"\n**************************************************\n" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-104}"
			;;
		*)
			echo -e "- Result - remediation failed\n- End Recommendation \"$RN - $RNA\"\n**************************************************\n" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_FAIL:-102}"
			;;
	esac
}