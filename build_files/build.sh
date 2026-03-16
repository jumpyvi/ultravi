#!/bin/bash

set -ouex pipefail

/ctx/branding/branding.sh
/ctx/packages/kernel.sh
/ctx/packages/dx.sh


