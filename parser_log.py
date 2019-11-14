if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(
        description="Deep Learning Recommendation Model (DLRM)"
    )
    parser.add_argument("--real-time", action="store_true", default=False)
    args = parser.parse_args()
    sum = 0
    if args.real_time:
        for i in range(14):
            core_sum = 0
            fp = open(r'./log/model1_CPU_PT_instance%d.log' % i)
            content = fp.readlines()
            for line in content[-10: -1]:
                core_sum += float(line.split(" ")[7])
            core_sum /= 9
            print("instance%d on core %d-%d: average %f ms/it" % (i, i * 4, i * 4 + 3, core_sum))
            sum += core_sum
        print("-----------------result---------------------")
        print("realtime: average %f ms/it" % (sum / 14))
    else:
        for i in range(2):
            core_sum = 0
            fp = open(r'./log/int8_throughput%d.log' % i)
            content = fp.readlines()
            for line in content[-10: -1]:
                core_sum += float(line.split(" ")[7])
            core_sum /= 9
            samples_per_second = 1 / core_sum * 1000 * 16
            print("instance%d on core %d-%d: average %f samples/s" % (i, i * 28, i * 28 + 27, samples_per_second))
            sum += samples_per_second
        print("-----------------result---------------------")
        print("throughput: average %f samples/s" % (sum / 2))


