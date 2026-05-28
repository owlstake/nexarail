"""NexaRail Python SDK — Local test. LOCAL DEVNET ONLY."""
import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))
import unittest
import nexarail_client as m

class TestSDKExports(unittest.TestCase):
    def test_required_exports(self):
        for name in ['get_params', 'get_list', 'get_detail']:
            self.assertTrue(hasattr(m, name), f"{name} should exist")

    def test_command_builders_exist(self):
        """Command builders return strings with valid args."""
        # bank_send_cmd(amount, denom, from_addr="", to="")
        result = m.bank_send_cmd("from", "to", "1000", "unxrl")
        self.assertIsInstance(result, str)
        self.assertGreater(len(result), 0)
        # merchant_register_cmd(owner, name, description)
        result = m.merchant_register_cmd("test_owner", "TestName", "Test desc")
        self.assertIsInstance(result, str)
        # settlement_create_cmd(payer, merchant, amount, reference)
        result = m.settlement_create_cmd("payer", "merchant", "1000", "test_ref")
        self.assertIsInstance(result, str)

    def test_no_private_key(self):
        src = str([k for k in dir(m) if not k.startswith('_')])
        self.assertNotIn('private_key', src.lower())
        self.assertNotIn('mnemonic', src.lower())

    def test_default_api(self):
        self.assertEqual(m.api_url(), 'http://localhost:1317')

if __name__ == '__main__':
    unittest.main()
