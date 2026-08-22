/* SPDX-FileCopyrightText: © 2019-2026 Nadim Kobeissi <nadim@symbolic.software>
 * SPDX-License-Identifier: GPL-3.0-only */

use zed_extension_api as zed;

struct VerifpalExtension;

impl zed::Extension for VerifpalExtension {
	fn new() -> Self {
		VerifpalExtension
	}
}

zed::register_extension!(VerifpalExtension);
