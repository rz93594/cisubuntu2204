#!/usr/bin/env bash
#
# CIS-LBK Cloud Team Built Recommendation Function
# ~/CIS-LBK/functions/recommendations/nix_deb_ensure_ntp_access_control_configured.sh
# 
# Name                Date       Description
# ------------------------------------------------------------------------------------------------
# Eric Pinnell       11/02/20    Recommendation "Ensure ntp access control is configured"
# David Neilson	   06/13/22		Updated to current standards
# Justin Brown			09/05/22		Small syntax changes

deb_ensure_ntp_access_control_configured()
{
	# Start recommendation entry for verbose log and output to screen
	echo -e "\n**************************************************\n- $(date +%d-%b-%Y' '%T)\n- Start Recommendation \"$RN - $RNA\"" | tee -a "$LOG" 2>> "$ELOG"
    l_test=""

    nix_package_manager_set()
	{
		echo "- Start - Determine system's package manager " | tee -a "$LOG" 2>> "$ELOG"
		if command -v rpm 2>/dev/null; then
			echo "- system is rpm based" | tee -a "$LOG" 2>> "$ELOG"
			G_PQ="rpm -q"
			command -v yum 2>/dev/null && G_PM="yum" && echo "- system uses yum package manager" | tee -a "$LOG" 2>> "$ELOG"
			command -v dnf 2>/dev/null && G_PM="dnf" && echo "- system uses dnf package manager" | tee -a "$LOG" 2>> "$ELOG"
			command -v zypper 2>/dev/null && G_PM="zypper" && echo "- system uses zypper package manager" | tee -a "$LOG" 2>> "$ELOG"
			G_PR="$G_PM -y remove"
			export G_PQ G_PM G_PR
			echo "- End - Determine system's package manager" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-101}"
		elif command -v dpkg 2>/dev/null; then
			echo -e "- system is apt based\n- system uses apt package manager" | tee -a "$LOG" 2>> "$ELOG"
			G_PQ="dpkg -s"
			G_PM="apt"
			G_PR="$G_PM -y purge"
			export G_PQ G_PM G_PR
			echo "- End - Determine system's package manager" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-101}"
		else
			echo -e "- FAIL:\n- Unable to determine system's package manager" | tee -a "$LOG" 2>> "$ELOG"
			G_PQ="unknown"
			G_PM="unknown"
			export G_PQ G_PM G_PR
			echo "- End - Determine system's package manager" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_FAIL:-102}"
		fi
	}

	deb_ensure_ntp_access_control_configured_chk()
	{
		echo "- Start check - Ensure ntp access control is configured" | tee -a "$LOG" 2>> "$ELOG"

		l_output="" l_output2="" l_restrict4="" l_param4_diff="" l_restrict6="" l_param6_diff=""
		l_params="kod nomodify notrap nopeer noquery"

		# Set package manager information
		if [ -z "$G_PQ" ] || [ -z "$G_PM" ] || [ -z "$G_PR" ]; then
			nix_package_manager_set
			[ "$?" != "101" ] && l_output="- Unable to determine system's package manager"
		fi

        if [ -z "$l_output" ]; then
            ! $G_PQ ntp | grep -Pq "^Status:\s+install\s+ok\s+installed" > /dev/null 2>&1 && l_test="NA"
		
            if [ "$l_test" != "NA" ]; then
                echo "- Checking restrict -4 entry" | tee -a "$LOG" 2>> "$ELOG"
                # Look for the string "restrict -4 default":
				if grep -Pq -- '^\s*restrict\s+-4\s*default' /etc/ntp.conf; then
					l_restrict4=$(grep -P -- 'restrict\h+-4\h+default' /etc/ntp.conf | sed -r 's/(restrict|-4|default)//g' | sed -r 's/\s+/ /g' | sed -r 's/^\s*//')
					l_param4_diff=$(echo "${l_params[@]}" "${l_restrict4[@]}" "${l_restrict4[@]}" | tr ' ' '\n' | sort | uniq -u)

					if [ -z "$l_param4_diff" ]; then
						l_output="$l_output\n- restrict -4 entry has parameters: $l_restrict4"
					else
						l_output2="$l_output2\n- restrict -4 entry is missing parameters: $l_param4_diff"
					fi
				else
					l_output2="$l_output2\n- NO restrict -4 entry found in /etc/ntp.conf"
				fi

				echo "- Checking restrict -6 entry" | tee -a "$LOG" 2>> "$ELOG"
                # Look for the string "restrict -4 default":
				if grep -Pq -- '^\s*restrict\s+-6\s*default' /etc/ntp.conf; then
					l_restrict6=$(grep -P -- 'restrict\h+-6\h+default' /etc/ntp.conf | sed -r 's/(restrict|-6|default)//g' | sed -r 's/\s+/ /g' | sed -r 's/^\s*//')
					l_param6_diff=$(echo "${l_params[@]}" "${l_restrict6[@]}" "${l_restrict6[@]}" | tr ' ' '\n' | sort | uniq -u)

					if [ -z "$l_param6_diff" ]; then
						l_output="$l_output\n- restrict -6 entry has parameters: $l_restrict6"
					else
						l_output2="$l_output2\n- restrict -6 entry is missing parameters: $l_param6_diff"
					fi
				else
					l_output2="$l_output2\n- NO restrict -6 entry found in /etc/ntp.conf"
				fi
            else
                echo -e "- NOT APPLICABLE:\n- NTP package not installed on the system" | tee -a "$LOG" 2>> "$ELOG"
                echo "- End check - Ensure ntp access control is configured" | tee -a "$LOG" 2>> "$ELOG"
                return "${XCCDF_RESULT_PASS:-104}"
            fi
        else
			# If we can't determine the pkg manager, need manual remediation
			echo -e "- FAILED:\n- $l_output" | tee -a "$LOG" 2>> "$ELOG"
			echo -e "- End check - Ensure ntp access control is configured" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-106}"
		fi

		if [ -z "$l_output2" ]; then
			echo -e "- PASS:\n$l_output\n" | tee -a "$LOG" 2>> "$ELOG"
			echo -e "- End check - Ensure ntp access control is configured" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-101}"
		else
			echo -e "- FAIL:\n- Failing values:\n$l_output2\n" | tee -a "$LOG" 2>> "$ELOG"
            if [ -n "$l_output" ]; then
                echo -e "- Passing values:\n$l_output\n" | tee -a "$LOG" 2>> "$ELOG"
            fi
			echo -e "- End check - Ensure ntp access control is configured" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_FAIL:-102}"
		fi
	}

	deb_ensure_ntp_access_control_configured_fix()
	{
		echo "- Start remediation - Ensure ntp access control is configured" | tee -a "$LOG" 2>> "$ELOG"

		if grep -Pq -- '^\s*(#\s*)?restrict\s+-4\s*default' /etc/ntp.conf; then
			if [ -n "$l_param4_diff" ]; then
				echo -e "- Updating restrict -4 entry in /etc/ntp.conf" | tee -a "$LOG" 2>> "$ELOG"
				echo -e "- Adding parameters: $(echo "$l_param4_diff" | tr '\n' ' ')" | tee -a "$LOG" 2>> "$ELOG"
				sed -ri "s/^\s*(#\s*)?(restrict\s+-4\s*default)([^#]+)?(\s*#.*)?$/\2\3 $(echo "$l_param4_diff" | tr '\n' ' ')\4/" /etc/ntp.conf
			fi
		else
			if grep -Pq -- "^\s*#\s+By\s+default,\s+exchange\s+time\s+with\s+everybody,\s+but\s+don't\s+allow\s+configuration\." /etc/ntp.conf; then
				echo -e "- Inserting restrict -4 entry to /etc/ntp.conf" | tee -a "$LOG" 2>> "$ELOG"
				sed -ri "/^\s*#\s+By\s+default,\s+exchange\s+time\s+with\s+everybody,\s+but\s+don't\s+allow\s+configuration\./a restrict -4 default kod nomodify notrap nopeer noquery" /etc/ntp.conf
			else
				echo -e "- Adding restrict -4 entry to /etc/ntp.conf" | tee -a "$LOG" 2>> "$ELOG"
				echo "restrict -4 default kod nomodify notrap nopeer noquery" >> /etc/ntp.conf
			fi
		fi

		if grep -Pq -- '^\s*(#\s*)?restrict\s+-6\s*default' /etc/ntp.conf; then
			if [ -n "$l_param6_diff" ]; then
				echo -e "- Updating restrict -6 entry in /etc/ntp.conf" | tee -a "$LOG" 2>> "$ELOG"
				echo -e "- Adding parameters: $(echo "$l_param6_diff" | tr '\n' ' ')" | tee -a "$LOG" 2>> "$ELOG"
				sed -ri "s/^\s*(#\s*)?(restrict\s+-6\s*default)([^#]+)?(\s*#.*)?$/\2\3 $(echo "$l_param6_diff" | tr '\n' ' ')\4/" /etc/ntp.conf
			fi
		else
			if grep -Pq -- "^\s*(#\s*)?restrict\s+-4\s*default" /etc/ntp.conf; then
				echo -e "- Inserting restrict -6 entry to /etc/ntp.conf" | tee -a "$LOG" 2>> "$ELOG"
				sed -ri "/^\s*(#\s*)?restrict\s+-4\s*default/a restrict -6 default kod nomodify notrap nopeer noquery" /etc/ntp.conf
			else
				echo -e "- Adding restrict -6 entry to /etc/ntp.conf" | tee -a "$LOG" 2>> "$ELOG"
				echo "restrict -6 default kod nomodify notrap nopeer noquery" >> /etc/ntp.conf
			fi
		fi

		echo "- End remediation - Ensure ntp access control is configured" | tee -a "$LOG" 2>> "$ELOG"
	}

	deb_ensure_ntp_access_control_configured_chk
	if [ "$?" = "101" ]; then
		[ -z "$l_test" ] && l_test="passed"
	else
        if [ "$l_test" != "manual" ] && [ "$l_test" != "NA" ]; then
            deb_ensure_ntp_access_control_configured_fix
            deb_ensure_ntp_access_control_configured_chk
            if [ "$?" = "101" ]; then
                [ "$l_test" != "failed" ] && l_test="remediated"
            else
                l_test="failed"
            fi
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