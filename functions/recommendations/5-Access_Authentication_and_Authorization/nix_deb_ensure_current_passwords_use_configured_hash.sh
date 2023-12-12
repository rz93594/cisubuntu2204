#!/usr/bin/env bash
#
# CIS-LBK Recommendation Function
# ~/CIS-LBK/functions/recommendations/nix_deb_ensure_current_passwords_use_configured_hash.sh
# 
# Name                Date       Description
# ------------------------------------------------------------------------------------------------
# Justin Brown       12/31/22    Recommendation "Ensure all current passwords uses the configured hashing algorithm"
# 
   
deb_ensure_current_passwords_use_configured_hash()
{
	echo -e "\n**************************************************\n- $(date +%d-%b-%Y' '%T)\n- Start Recommendation \"$RN - $RNA\"" | tee -a "$LOG" 2>> "$ELOG"
    l_test=""
   
    deb_ensure_current_passwords_use_configured_hash_chk()
	{
        echo -e "- Start check - Ensure all current passwords uses the configured hashing algorithm" | tee -a "$LOG" 2>> "$ELOG"
        l_output="" l_output2=""

        declare -A HASH_MAP=( ["y"]="yescrypt" ["1"]="md5" ["2"]="blowfish" ["5"]="SHA256" ["6"]="SHA512" ["g"]="gost-yescrypt" )

        CONFIGURED_HASH=$(sed -n "s/^\s*ENCRYPT_METHOD\s*\(.*\)\s*$/\1/p" /etc/login.defs | xargs)

        for MY_USER in $(sed -n "s/^\(.*\):\\$.*/\1/p" /etc/shadow); do
            CURRENT_HASH=$(sed -n "s/${MY_USER}:\\$\(.\).*/\1/p" /etc/shadow)
            if [[ "${HASH_MAP["${CURRENT_HASH}"]^^}" != "${CONFIGURED_HASH^^}" ]]; then 
                l_output2="$l_output2\nThe password for '${MY_USER}' is using '${HASH_MAP["${CURRENT_HASH}"]}' instead of the configured '${CONFIGURED_HASH}'."
            else
                l_output="$l_output\nThe password for '${MY_USER}' is using '${HASH_MAP["${CURRENT_HASH}"]}'."
            fi
        done

        if [ -z "$l_output2" ]; then
			echo -e "- PASS:\n$l_output" | tee -a "$LOG" 2>> "$ELOG"
			echo -e "- End check - Ensure all current passwords uses the configured hashing algorithm" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-101}"
		else
			echo -e "- FAIL:\n- Failing values:\n$l_output2" | tee -a "$LOG" 2>> "$ELOG"
            if [ -n "$l_output" ]; then
                echo -e "- Passing values:\n$l_output" | tee -a "$LOG" 2>> "$ELOG"
            fi
			echo -e "- End check - Ensure all current passwords uses the configured hashing algorithm" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_FAIL:-102}"
		fi
    }
   
    deb_ensure_current_passwords_use_configured_hash_fix()
	{
        echo -e "- Start remediation - Ensure all current passwords uses the configured hashing algorithm" | tee -a "$LOG" 2>> "$ELOG"

        echo -e "- Any passwords that are not using the configured hashing algorithm can be updated by resetting the password." | tee -a "$LOG" 2>> "$ELOG"
        l_test="manual"

        echo -e "- End remediation - Ensure all current passwords uses the configured hashing algorithm" | tee -a "$LOG" 2>> "$ELOG"
    }
   
    deb_ensure_current_passwords_use_configured_hash_chk
    if [ "$?" = "101" ]; then
        [ -z "$l_test" ] && l_test="passed"
    else
        if [ "$l_test" != "NA" ]; then
            deb_ensure_current_passwords_use_configured_hash_fix
            if [ "$l_test" != "manual" ] ; then
                deb_ensure_current_passwords_use_configured_hash_chk
                if [ "$?" = "101" ] ; then
                    [ "$l_test" != "failed" ] && l_test="remediated"
                else
                    l_test="failed"
                fi
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