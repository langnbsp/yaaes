#!/usr/bin/env python3

"""Generate test vectors and a test suite for the AES VHDL design."""


from binascii import a2b_hex
import itertools

from Cryptodome.Cipher import AES

import common


def xor(str1, str2):
    """xor two hexadecimal strings."""
    assert len(str1) == len(str2), "bitwidth should be equal"
    return format(int(str1, 16) ^ int(str2, 16), "0%dx" % len(str1))


def encrypt(plaintext, key, iv, mode):
    """Encrypt the given plaintext."""
    if mode == "ECB":
        cipher = AES.new(a2b_hex(key), AES.MODE_ECB)
        ciphertext = cipher.encrypt(a2b_hex(plaintext)).hex()
        next_iv = iv
    elif mode == "CBC":
        cipher = AES.new(a2b_hex(key), AES.MODE_CBC, iv=a2b_hex(iv))
        ciphertext = cipher.encrypt(a2b_hex(plaintext)).hex()
        next_iv = ciphertext
    elif mode == "CFB":
        cipher = AES.new(a2b_hex(key), AES.MODE_CFB, iv=a2b_hex(iv),
                         segment_size=128)
        ciphertext = cipher.encrypt(a2b_hex(plaintext)).hex()
        next_iv = ciphertext
    elif mode == "OFB":
        cipher = AES.new(a2b_hex(key), AES.MODE_OFB, iv=a2b_hex(iv))
        ciphertext = cipher.encrypt(a2b_hex(plaintext)).hex()
        # calculate next iv manually, since it's not available
        next_iv = xor(plaintext, ciphertext)

    return ciphertext, next_iv


def decrypt(ciphertext, key, iv, mode):
    """Decrypt the given ciphertext."""
    if mode == "ECB":
        return None
    elif mode == "CBC":
        return None
    elif mode == "CFB":
        cipher = AES.new(a2b_hex(key), AES.MODE_CFB, iv=a2b_hex(iv),
                         segment_size=128)
        plaintext = cipher.decrypt(a2b_hex(ciphertext)).hex()
        next_iv = ciphertext
    elif mode == "OFB":
        cipher = AES.new(a2b_hex(key), AES.MODE_OFB, iv=a2b_hex(iv))
        plaintext = cipher.encrypt(a2b_hex(ciphertext)).hex()
        # calculate next iv manually, since it's not available
        next_iv = xor(plaintext, ciphertext)

    return plaintext, next_iv


def create_test_suite(lib):
    """Create a testsuite for the aes module."""
    tb_aes = lib.entity("tb_aes")

    # test configs
    # TODO: duplicated at aes selftest
    # TODO: allow more variability, e. g. varying segment_size for CFB
    cfg1 = {  # test vector from: FIPS-197, Appendix B
        "input": "same",
        "C_PLAINTEXT1": "3243f6a8885a308d313198a2e0370734",
        "C_PLAINTEXT2": "3243f6a8885a308d313198a2e0370734",
        "C_KEY": "2b7e151628aed2a6abf7158809cf4f3c",
    }
    cfg2 = {
        "input": "different",
        "C_PLAINTEXT1": "3243f6a8885a308d313198a2e0370734",
        "C_PLAINTEXT2": "000102030405060708090a0b0c0d0e0f",
        "C_KEY": "2b7e151628aed2a6abf7158809cf4f3c",
    }
    cfg3 = {
        "input": "random",
        "C_PLAINTEXT1": common.random_hex(32),
        "C_PLAINTEXT2": common.random_hex(32),
        "C_KEY": common.random_hex(32),
    }
    cfg4 = {  # test vector from: FIPS-197, Appendix C.3
        "input": "same",
        "C_PLAINTEXT1": "00112233445566778899aabbccddeeff",
        "C_PLAINTEXT2": "00112233445566778899aabbccddeeff",
        "C_KEY": "000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f",
    }

    # simulate two rounds of en- and decrypting for each chaining mode
    # TODO: implement counter mode. this would require some more input signals
    test_params = itertools.product((0, 1), ("ECB", "CBC", "CFB", "OFB"),
                                    (cfg1, cfg2, cfg3, cfg4))
    for encryption, mode, gen in test_params:
        if not encryption and mode in ["ECB", "CBC"]:
            continue  # not yet implemented

        # TODO: python byteorder is LSB...MSB, VHDL is MSB downto LSB
        encr_str = "encrypt" if encryption else "decrypt"
        encr_func = encrypt if encryption else decrypt
        bw = 128
        bw_key = len(gen["C_KEY"]) * 4  # 2 hex chars -> 8 bits
        init_vector = common.random_hex(32)

        ciphertext1, iv2 = encr_func(
            gen["C_PLAINTEXT1"], gen["C_KEY"], init_vector, mode)
        ciphertext2, _ = encr_func(
            gen["C_PLAINTEXT2"], gen["C_KEY"], iv2, mode)
        gen.update({
            "C_ENCRYPTION": encryption,
            "C_BITWIDTH_IF": bw,
            "C_BITWIDTH_KEY": bw_key,
            "C_MODE": mode,
            "C_CIPHERTEXT1": ciphertext1,
            "C_CIPHERTEXT2": ciphertext2,
            "C_IV": init_vector,
        })
        generics = {k: v for k, v in gen.items() if k != "input"}
        tb_aes.add_config(
            name="aes_%d_%s_mode_%s_bw_%d_input_%s" % (
                bw_key, encr_str, mode, bw, gen["input"]),
            generics=generics)

        if gen["input"] == "random":
            # Add test for 8 and 32 bit bitwidth.
            # Use stimuli and references from updated gen3.
            for bw in (8, 32):
                tb_aes.add_config(name="aes_%d_%s_mode=%s_bw=%d_input=random"
                                  % (bw_key, encr_str, mode, bw),
                                  generics=generics)
