#!/usr/bin/env bash
#
# CIS-LBK Recommendation Function
# ~/CIS-LBK/functions/recommendations/nix_deb_ensure_password_creation_requirements_configured.sh
# 
# Name              Date       	Description
# ------------------------------------------------------------------------------------------------
# Justin Brown      12/31/22    Recommendation "Ensure password creation requirements are configured"
# J. Brown			03/08/23	Corrected bug in _fix function
# 
   
deb_ensure_password_creation_requirements_configured()
{
    nix_package_manager_set()
	{
		echo -e "- Start - Determine system's package manager " | tee -a "$LOG" 2>> "$ELOG"

		if command -v rpm 2>/dev/null; then
			echo -e "- system is rpm based" | tee -a "$LOG" 2>> "$ELOG"
			G_PQ="rpm -q"
			command -v yum 2>/dev/null && G_PM="yum" && echo "- system uses yum package manager" | tee -a "$LOG" 2>> "$ELOG"
			command -v dnf 2>/dev/null && G_PM="dnf" && echo "- system uses dnf package manager" | tee -a "$LOG" 2>> "$ELOG"
			command -v zypper 2>/dev/null && G_PM="zypper" && echo "- system uses zypper package manager" | tee -a "$LOG" 2>> "$ELOG"
			G_PR="$G_PM -y remove"
			export G_PQ G_PM G_PR
			echo -e "- End - Determine system's package manager" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-101}"
		elif command -v dpkg 2>/dev/null; then
			echo -e "- system is apt based\n- system uses apt package manager" | tee -a "$LOG" 2>> "$ELOG"
			G_PQ="dpkg -s"
			G_PM="apt"
			G_PR="$G_PM -y purge"
			export G_PQ G_PM G_PR
			echo -e "- End - Determine system's package manager" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-101}"
		else
			echo -e "- FAIL:\n- Unable to determine system's package manager" | tee -a "$LOG" 2>> "$ELOG"
			G_PQ="unknown"
			G_PM="unknown"
			export G_PQ G_PM G_PR
			echo -e "- End - Determine system's package manager" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_FAIL:-102}"
		fi
	}

	echo -e "\n**************************************************\n- $(date +%d-%b-%Y' '%T)\n- Start Recommendation \"$RN - $RNA\"" | tee -a "$LOG" 2>> "$ELOG"
    l_test=""
   
    deb_ensure_password_creation_requirements_configured_chk()
	{
        echo -e "- Start check - Ensure password creation requirements are configured" | tee -a "$LOG" 2>> "$ELOG"
        l_output="" l_testpkg="" l_test1="" l_test2=""

        # Set package manager information
		if [ -z "$G_PQ" ] || [ -z "$G_PM" ] || [ -z "$G_PR" ]; then
			nix_package_manager_set
			[ "$?" != "101" ] && l_output="- Unable to determine system's package manager"
		fi
	
		# Check to see if libpam-pwquality is installed.  If not, we pass.
		if [ -z "$l_output" ]; then
			case "$G_PQ" in 
				*dpkg*)
					if $G_PQ libpam-pwquality; then
                        l_output="$l_output\n- libpam-pwquality package was found"	
						l_testpkg=passed
					else
						l_output="$l_output\n- libpam-pwquality package was NOT found"
					fi
				;;
			esac
		fi
      
        # Check password length
        if grep -Eqs '^\s*minlen\s*=\s*(1[4-9]|[2-9][0-9]|[1-9][0-9]{2,})\b' /etc/security/pwquality.conf; then
            l_output="$l_output\n- Correct password length setting found in /etc/security/pwquality.conf: $(grep -Es '^\s*minlen\s*=\s*(1[4-9]|[2-9][0-9]|[1-9][0-9]{2,})\b' /etc/security/pwquality.conf)"
            l_test1=passed
        elif grep -Eqs '^\s*(#\s*)?minlen\s*=' /etc/security/pwquality.conf; then
            l_output="$l_output\n- Incorrect password length setting found in /etc/security/pwquality.conf: $(grep -Es '^\s*(#\s*)?minlen\s*=' /etc/security/pwquality.conf)"
        else
            l_output="$l_output\n- No minlen setting found in /etc/security/pwquality.conf"
        fi
      
        # Check password complexity
        if grep -Eqs '^\s*minclass\s*=\s*4\b' /etc/security/pwquality.conf; then
            l_output="$l_output\n- Correct minclass setting found in /etc/security/pwquality.conf: $(grep -Es '^\s*minclass\s*=\s*4\b' /etc/security/pwquality.conf)"
            l_test2=passed
        elif grep -Eqs '^\s*(#\s*)?minclass\s*=' /etc/security/pwquality.conf; then
            l_output="$l_output\n- Incorrect minclass setting found in /etc/security/pwquality.conf: $(grep -Es '^\s*(#\s*)?minclass\s*=' /etc/security/pwquality.conf)"
        else
            l_output="$l_output\n- No minclass setting found in /etc/security/pwquality.conf"
        fi   
      
        if [ -z "$l_test2" ]; then
            if grep -Eqs '^\s*dcredit\s*=\s*-[1-9]\b' /etc/security/pwquality.conf && grep -Eqs '^\s*ucredit\s*=\s*-[1-9]\b' /etc/security/pwquality.conf && grep -Eqs '^\s*ocredit\s*=\s*-[1-9]\b' /etc/security/pwquality.conf && grep -Eqs '^\s*lcredit\s*=\s*-[1-9]\b' /etc/security/pwquality.conf; then
                l_output="$l_output\n- Correct dcredit, ucredit, ocredit and lcredit settings found in /etc/security/pwquality.conf:\n$( grep -Es '^\s*[duol]credit\s*=' /etc/security/pwquality.conf)"
                l_test2=passed
            elif grep -Eqs '^\s*(#\s*)?dcredit\s*=' /etc/security/pwquality.conf || grep -Eqs '^\s*(#\s*)?ucredit\s*=' /etc/security/pwquality.conf && grep -Eqs '^\s*(#\s*)?ocredit\s*=' /etc/security/pwquality.conf || grep -Eqs '^\s*(#\s*)?lcredit\s*=' /etc/security/pwquality.conf; then
                l_output="$l_output\n- Incorrect dcredit, ucredit, ocredit and lcredit settings found in /etc/security/pwquality.conf:\n$( grep -Es '^\s*(#\s*)?[duol]credit\s*=' /etc/security/pwquality.conf)"
            else
                l_output="$l_output\n- No dcredit, ucredit, ocredit or lcredit settings found in /etc/security/pwquality.conf"
            fi
        fi
      
        if [ "$l_testpkg" = "passed" ] && [ "$l_test1" = "passed" ] && [ "$l_test2" = "passed" ]; then
			echo -e "- PASS:\n$l_output" | tee -a "$LOG" 2>> "$ELOG"
			echo -e "- End check - Ensure password creation requirements are configured" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-101}"
		else
			echo -e "- FAIL:\n$l_output" | tee -a "$LOG" 2>> "$ELOG"
			echo -e "- End check - Ensure password creation requirements are configured" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_FAIL:-102}"
		fi
    }
   
    deb_ensure_password_creation_requirements_configured_fix()
	{
        echo -e "- Start remediation - Ensure password creation requirements are configured" | tee -a "$LOG" 2>> "$ELOG"

        if [ "$l_testpkg" != "passed" ]; then
            $G_PM install libpam-pwquality
            echo -e "- Installing libpam-pwquality package" | tee -a "$LOG" 2>> "$ELOG"
        fi 
        
        if [ "$l_test1" != "passed" ]; then
            if grep -Eqs '^\s*(#\s*)?minlen\s*=' /etc/security/pwquality.conf; then
                echo -e "- Updating minlen entry in /etc/security/pwquality.conf" | tee -a "$LOG" 2>> "$ELOG"
                sed -ri 's/^\s*(#\s*)?(minlen\s*=)(\s*\S+\s*)(\s+#.*)?$/\2 14\4/' /etc/security/pwquality.conf
            else
                echo -e "- Adding minlen entry to /etc/security/pwquality.conf" | tee -a "$LOG" 2>> "$ELOG"
                echo "minlen = 14" >> /etc/security/pwquality.conf
            fi
        fi
            
        if [ "$l_test2" != "passed" ]; then
            if grep -Eqs '^\s*(#\s*)?minclass\s*=' /etc/security/pwquality.conf; then
                echo -e "- Updating minclass entry in /etc/security/pwquality.conf" | tee -a "$LOG" 2>> "$ELOG"
                sed -ri 's/^\s*(#\s*)?(minclass\s*=)(\s*\S+\s*)(\s+#.*)?$/\2 4\4/' /etc/security/pwquality.conf
            else
                echo -e "- Adding minclass entry to /etc/security/pwquality.conf" | tee -a "$LOG" 2>> "$ELOG"
                echo "minclass = 4" >> /etc/security/pwquality.conf
            fi
        fi
        
        echo -e "- End remediation - Ensure password creation requirements are configured" | tee -a "$LOG" 2>> "$ELOG"
    }
   
    deb_ensure_password_creation_requirements_configured_chk
    if [ "$?" = "101" ]; then
        [ -z "$l_test" ] && l_test="passed"
    else
        if [ "$l_test" != "NA" ]; then
            deb_ensure_password_creation_requirements_configured_fix
            deb_ensure_password_creation_requirements_configured_chk
			if [ "$?" = "101" ]; then
               [ "$l_test" != "failed" ] && l_test="remediated"
            else
               l_test="failed"
            fi
        fi
    fi
	
	# Set return code and return
	case "$l_test" in
		passed)
			echo "Recommendation \"$RNA\" No remediation required" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-101}"
			;;
		remediated)
			echo "Recommendation \"$RNA\" successfully remediated" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-103}"
			;;
		manual)
			echo "Recommendation \"$RNA\" requires manual remediation" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_FAIL:-106}"
			;;
		NA)
			echo "Recommendation \"$RNA\" Something went wrong - Recommendation is non applicable" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-104}"
			;;
		*)
			echo "Recommendation \"$RNA\" remediation failed" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_FAIL:-102}"
			;;
	esac
}